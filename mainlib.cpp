#include <file_utils.h>
#include <debug_logger.h>
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <string>
#include <lvgl/lvgl.h>
#include <lv_drivers/sdl/sdl.h>
#include <lvgl/demos/lv_demos.h>
#include <lvgl/examples/lv_examples.h>
#include <sys/stat.h>
#include <dirent.h> 
#include <sys/time.h>
#include <unistd.h>
#include <vector>

#include "rendering_engine.h"
#include "ssh_session.h"
#include "scp_session.h"

LOG_CATEGORY(MAIN, "MAIN")

static void taEventCallback(lv_event_t * e){ 
    lv_event_code_t code = lv_event_get_code(e);
    // _machine_ta = lv_event_get_target(e);
    
    if(code == LV_EVENT_CLICKED 
      /*&& lv_event_get_target(e)==_machine_ta*/){
    }
}


static lv_obj_t * _label;
static lv_obj_t * _ta;
static void addTextBox()
{
    static lv_style_t style;
    lv_style_init(&style);
    lv_style_set_radius(&style, 5);

    lv_style_set_width(&style, 500);
    lv_style_set_height(&style, LV_SIZE_CONTENT);

    lv_style_set_pad_ver(&style, 20);
    lv_style_set_pad_left(&style, 5);

    lv_style_set_x(&style, lv_pct(10));
    lv_style_set_y(&style, 70);

    /*Create an object with the new style*/
    lv_obj_t * obj = lv_obj_create(lv_scr_act());
    lv_obj_add_style(obj, &style, 0);

    _label = lv_label_create(obj);
    lv_label_set_text(_label, "Serial#");
    lv_obj_add_event_cb(_label, taEventCallback, LV_EVENT_CLICKED, nullptr);
}

static void addTextArea()
{
    _ta = lv_textarea_create(lv_scr_act());
    lv_textarea_set_text(_ta, "");
    lv_obj_align(_ta, LV_ALIGN_TOP_MID, 0, 78);
    lv_obj_set_size(_ta, 330, 42);
    lv_textarea_set_max_length(_ta, 15);
    lv_textarea_set_text_selection(_ta, true);
    lv_textarea_set_one_line(_ta, true);
    // lv_obj_add_event_cb(_ta, taEventCallback, LV_EVENT_VALUE_CHANGED, nullptr);
    // lv_obj_add_event_cb(_ta, taEventCallback, LV_EVENT_CLICKED, nullptr);
    lv_obj_add_event_cb(_ta, taEventCallback, LV_EVENT_READY/*when enter key is pressed*/, nullptr);
}

static void keypressEvent(uint32_t key, uint32_t btn_id)
{
    printf( "@@@@@@@@ %c\n", key );
    // const char* p = lv_label_get_text(_label);
    // if(p){
    //   std::string text(p);
    //   text.push_back(key);
    //   lv_label_set_text(_label, text.c_str());
    // }
}
static void eventLoop(int loop_count)
{
  for (int i = 0; loop_count < 0 || i < loop_count; ++i){
    /* Periodically call the lv_task handler.
       * It could be done in a timer interrupt or an OS task too.*/
    lv_timer_handler();
    usleep(1000);
  }
}

extern "C" int FactoryInstallerEntryPoint(int argc, char** argv)
{
  setProgramName(argv[0]);
  LOG(DEBUG, MAIN, "FactoryInstallerEntryPoint\n");  
  init_rendering_engine_sdl(keypressEvent);//wayland_init1(); or framebuffer init or sdl, we want to use sdl for x86
  lv_obj_t *screen = lv_obj_create(nullptr);
  addTextBox();
  addTextArea();

  ssh_init();
   //oosman@192.168.4.127
  SshSession ssh_session([](const std::string &title, const std::string &message){
	LOG(DEBUG, MAIN, "%s:%s\n", title.c_str(), message.c_str());
   });
   auto keep_waiting = 	[](){
		eventLoop(1);
		return true;
	};
  if(!ssh_session.Connect(
    "192.168.4.143", //osm todo should be configurable
    22,
    "oosman",
    "a",
    keep_waiting)){
  	LOG(FATAL, MAIN, "FAILD to Connect\n");
    }
	LOG(DEBUG, MAIN, "Connected\n");

  std::string cmd("ls -alh . > /tmp/foobar");
  ssh_session.ExecuteRemoteCommand(cmd, keep_waiting, [](const char *buffer, int nbytes){
    if(nbytes > 0){
  	  LOG(DEBUG, MAIN, "%s\n", buffer);
    }
    return true;
    }
  );

  ScpSession scp_session(ssh_session.GetSession());
  scp_session.ReadRemoteFile("/tmp/foobar", keep_waiting, [](const char *buffer, int nbytes){
	  LOG(DEBUG, MAIN, "ReadRemoteFile\n");
    if(nbytes > 0){
  	  LOG(DEBUG, MAIN, "Read %i bytes of data from remote\n", nbytes);
      FILE *fp = fopen(
#if defined(WIN32) || defined(MSYS)
        "c:/users/oosman/foobar", 
#else
        "/tmp/foobar",
#endif
        "a+b");
      fwrite(buffer, nbytes, 1, fp);
      fclose(fp);
    }
    return nbytes;
    }
  );

    struct stat st;
    stat("c:/Users/oosman/fava", &st);
    size_t file_size = st.st_size;
    FILE *fp = fopen("c:/Users/oosman/fava", "rb");
    scp_session.WriteRemoteFile("/tmp/barfile", file_size, keep_waiting, [fp](char *buffer, int nbytes){
      ssize_t bytes_read = fread(buffer, 1, nbytes, fp);
  	  LOG(DEBUG, MAIN, "WriteRemoteFile bytes %i\n", bytes_read);
      return bytes_read;
    }
  );

	eventLoop(-1);
	ssh_finalize();
  LOG(DEBUG, MAIN, "Exit\n");
  return 0;
}