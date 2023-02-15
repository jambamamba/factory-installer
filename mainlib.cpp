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


#include "rendering_engine.h"
#include "ssh_session.h"
#include "scp_session.h"

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
}
static void keypressEvent(uint32_t key, uint32_t btn_id)
{
    // printf( "@@@@@@@@ %c\n", key );
    // const char* p = lv_label_get_text(_label);
    // if(p){
    //   std::string text(p);
    //   text.push_back(key);
    //   lv_label_set_text(_label, text.c_str());
    // }
}
static FILE * _fp = stdout;
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
 _fp = fopen("log.txt", "wt");
  fprintf(_fp, "starting factory-installer\n");
  init_rendering_engine_sdl(keypressEvent);//wayland_init1(); or framebuffer init or sdl, we want to use sdl for x86
  lv_obj_t *screen = lv_obj_create(nullptr);
  addTextBox();
  addTextArea();

   //oosman@192.168.4.127
   SshSession ssh_session([](const std::string &title, const std::string &message){
	fprintf(_fp, "%s:%s\n", title.c_str(), message.c_str());
   });
   auto keep_waiting = 	[](){
		eventLoop(1);
		return true;
	};
  ssh_session.Connect(
	"192.168.4.142", 
	22,
	"oosman",
	"a",
  keep_waiting);
	fprintf(_fp, "connected\n");

  std::string cmd("ls -alh . > /tmp/foobar");
  ssh_session.ExecuteRemoteCommand(cmd, keep_waiting, [](const char *buffer, int nbytes){
    if(nbytes > 0){
  	  fprintf(_fp, "%s\n", buffer);
    }
    return true;
    }
  );
#if 0 

  ScpSession scp_session(ssh_session.GetSession());
  scp_session.ReadRemoteFile("/tmp/foobar", keep_waiting, [](const char *buffer, int nbytes){
    if(nbytes > 0){
  	  fprintf(_fp, "%s\n", buffer);
    }
    return true;
    }
  );

    struct stat st;
    stat("c:/Users/oosman/fava", &st);
    size_t file_size = st.st_size;
    FILE *fp = fopen("c:/Users/oosman/fava", "rb");
    scp_session.WriteRemoteFile("/tmp/barfile", file_size, keep_waiting, [fp](char *buffer, int nbytes){
    ssize_t bytes_read = fread(buffer, 1, nbytes, fp);
    return bytes_read;
    }
  );
#endif
	eventLoop(-1);
	fclose(_fp);
  return 0;
}