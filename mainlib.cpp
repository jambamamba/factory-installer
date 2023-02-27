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
#include <SDL2/SDL.h>
#include <thread>

#include "json_utils.h"
#include "rendering_engine.h"
#include "ssh_session.h"
#include "scp_session.h"
#include "python_wrapper.h"
#include "my_device.h"

LOG_CATEGORY(MAIN, "MAIN")

namespace {
static lv_obj_t * _label_serialnum;
static lv_obj_t * _ta;
static lv_obj_t * _arc;
static lv_obj_t * _label_status;
static bool _die;
enum SshStateE {
  SshState_None = 0,
  SshState_Connecting,
  SshState_Connected,
  SshState_SettingSerialNumber,
};
static std::thread _task;


static bool
updateSerialNumberInJson(const std::string &local_serialnum_file, const std::string &serialnum){
  cJSON* json = readJson(local_serialnum_file.c_str());
  if(!json){
    return false;
  }
  cJSON* serialnum_json = cJSON_GetObjectItemCaseSensitive(json, "Serial Number");
  if(!serialnum_json){
    return false;
  }
  if(!cJSON_SetValuestring(serialnum_json, serialnum.c_str())){
    return false;
  }
  storeJsonToFile(cJSON_Print(json), local_serialnum_file.c_str());
  return true;
}

static std::string _status_msg;
static SshStateE _state = SshState_None;
static void 
setDeviceSerialNum(MyDevice *device, const char *serialnum){
  _task = std::thread([device, serialnum](){
    std::string workdir(SDL_GetPrefPath("", APP_NAME));
    std::string local_serialnum_file = workdir + "serial_number.json";
    LOG(DEBUG, MAIN, "CONNECTING ....\n");
    _state = SshState_Connecting;
    _status_msg = std::string("Connecting to ") + device->ip();
    if(!device->openSession()){
      _state = SshState_None;
      _status_msg = std::string("Connection failed.\n") + 
        std::string("Is the device with IP ") + device->ip() + 
        std::string(" on your network?");
        return;
    }
    _state = SshState_Connected;
    _status_msg = std::string("Connected to ") + device->ip();
    // device.runCommand("ls -alh . > /tmp/foobar");
    device->getSerialNumberFile(local_serialnum_file);
    if(FileUtils::fileExists(local_serialnum_file)){
      if(!updateSerialNumberInJson(local_serialnum_file, serialnum)){
      _state = SshState_None;
      _status_msg = std::string("Failed to set serial number on device:\n") + device->ip();
        return;
      }
      _state = SshState_SettingSerialNumber;
      _status_msg = std::string("Setting serial number '") + std::string(serialnum) + "'\n" +
        std::string(" to device ") + device->ip();
      device->putSerialNumberFile(local_serialnum_file);
    }
  });
}

static void taEventCallback(lv_event_t * e){ 
    lv_event_code_t code = lv_event_get_code(e);
    // _machine_ta = lv_event_get_target(e);
    
//    LOG(DEBUG, MAIN, "taEventCallback code: %i, target:%x, _ta:%x\n", code, lv_event_get_target(e), _ta);
    if(code == LV_EVENT_CLICKED 
      && lv_event_get_target(e)==_ta){
        MyDevice *device = static_cast<MyDevice*>(lv_event_get_user_data(e));
        const char * text = lv_textarea_get_text(_ta);
        LOG(DEBUG, MAIN, "taEventCallback text: %s\n", text);
        setDeviceSerialNum(device, text);
    }
}
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

    _label_serialnum = lv_label_create(obj);
    lv_label_set_text(_label_serialnum, "Serial#");
}

static void addTextArea(MyDevice &device)
{
    _ta = lv_textarea_create(lv_scr_act());
    lv_textarea_set_text(_ta, "");
    lv_obj_align(_ta, LV_ALIGN_TOP_MID, 0, 78);
    lv_obj_set_size(_ta, 330, 42);
    lv_textarea_set_max_length(_ta, 15);
    lv_textarea_set_text_selection(_ta, true);
    lv_textarea_set_one_line(_ta, true);
    lv_obj_add_event_cb(_ta, taEventCallback, LV_EVENT_CLICKED, &device);//also triggered when Enter key is pressed
}

static void addStatusMessage()
{
    _label_status = lv_label_create(lv_scr_act());
    lv_label_set_text(_label_status, "");
    lv_obj_align(_label_status, LV_ALIGN_TOP_MID, 0, 148);
    lv_obj_set_size(_label_status, 330, 42);
}

static void addLoaderArc()
{
  _arc = lv_arc_create(lv_scr_act());
  lv_arc_set_bg_angles(_arc, 0, 360);
  lv_arc_set_angles(_arc, 270, 270);
  lv_obj_align(_arc, LV_ALIGN_CENTER, 0, 0);
  // lv_obj_set_size(_arc, 0, 0);
}

static void keypressEvent(uint32_t key, uint32_t btn_id)
{
    printf( "@@@@@@@@ %i:%i\n", key, btn_id );
    if(key == 10 && btn_id == 0){
      //osm todo: send serial number from _ta to device
    }
    // const char* p = lv_label_get_text(_label_serialnum);
    // if(p){
    //   std::string text(p);
    //   text.push_back(key);
    //   lv_label_set_text(_label_serialnum, text.c_str());
    // }
}
static void windowEventCallback(struct SDL_WindowEvent *window)
{
  if(window->event == SDL_WINDOWEVENT_CLOSE){
    _die = true;
    _task.join();
  }
}

static void 
updateArcAnlge() {
  // LOG(DEBUG, MAIN, "SHOWING ....\n");
  static int angle = 0;
  lv_arc_set_end_angle(_arc, angle);
  angle += 1;
}

static void     
updateWithSshActivity(){
  static SshStateE prev_state = SshState_None;
  switch(_state){
    case SshState_Connecting:
      updateArcAnlge();
      LOG(DEBUG, MAIN, "WAITING ....\n");
      if(prev_state != _state){
        lv_obj_clear_flag(_arc, LV_OBJ_FLAG_HIDDEN);
        lv_label_set_text(_label_status, _status_msg.c_str());
      }
      break;
    case SshState_Connected:
      if(prev_state != _state){
        lv_obj_add_flag(_arc, LV_OBJ_FLAG_HIDDEN);
        lv_label_set_text(_label_status, _status_msg.c_str());
      }
      break;
    case SshState_SettingSerialNumber:
      if(prev_state != _state){
        lv_label_set_text(_label_status, _status_msg.c_str());
      }
      break;
    case SshState_None:
      if(prev_state != _state){
        lv_obj_add_flag(_arc, LV_OBJ_FLAG_HIDDEN);
        lv_label_set_text(_label_status, _status_msg.c_str());
      }
      break;
  }
  prev_state = _state;
}

static void 
eventLoop(PythonWrapper &py, MyDevice &device, int loop_count)
{
  for (int i = 0; !_die && (loop_count < 0 || i < loop_count); ++i){
    updateWithSshActivity();
    if(!py.eventLoop()){
      return;
    }
    lv_timer_handler();
    usleep(10*1000);
  }
    // SDL_Delay

}

static std::string configPath(const std::string &filename)
{
    std::string path = SDL_GetPrefPath("", FileUtils::getProgramName().c_str());
    LOG(DEBUG, MAIN, "configPath, 1-trying path %s\n", path.c_str());  
    if(FileUtils::fileExists(std::string(path + filename))){
      return FileUtils::toLinuxPathSeparators(path + filename);
    }

    path = FileUtils::getProgramPath();
    LOG(DEBUG, MAIN, "configPath, 2-trying path %s\n", (path + "/config.json").c_str());  
    if(FileUtils::fileExists(path + "/config.json")){
      return FileUtils::toLinuxPathSeparators(path + "/config.json");
    }

    LOG(DEBUG, MAIN, "configPath, 3-trying path %s\n", filename.c_str());  
    if(FileUtils::fileExists(filename)){
      return filename;
    }

    LOG(FATAL, MAIN, "configPath, exhausted all options\n");  
    return "";
}

static PythonWrapper loadPython(int argc, char** argv)
{
  PythonWrapper py;
  if(py.pythonInit(argc, argv, configPath("cmain.py").c_str())){
    // py.registerTouchWidgetProcs(
    //   [](const char* widget_id){
    //     // ScreenManager::getScreenManager()->loadScreenById(widget_id);
    //     return true;
    //   },
    //   [](const char* widget_id){
    //     return true;//return touchWidgetById(widget_id);
    //   },
    //   [](const char *obj_text, int nth_obj){
    //     return true;//return touchWidgetByText(obj_text, nth_obj);
    //   },
    //   [](int32_t x, int32_t y){
    //     return true;//return touchScreenAtPoint(x, y);
    //   },
    //   [](int32_t x, int32_t y){
    //     return "";//return getWidgetTextOnScreenAt(x, y);
    //   } 
    // );
  }
  return py;
}

}//namespace

extern "C" int FactoryInstallerEntryPoint(int argc, char** argv)
{
  PROGRAM_INIT(argv[0], SDL_GetPrefPath("", APP_NAME));
  LOG(DEBUG, MAIN, "FactoryInstallerEntryPoint\n");  

  PythonWrapper py = loadPython(argc, argv);
  MyDevice device(configPath("config.json").c_str(), [](){
    return !_die;
  });

  initRenderingEngineSDL(keypressEvent, windowEventCallback);//wayland_init1(); or framebuffer init or sdl, we want to use sdl for x86
  lv_obj_t *screen = lv_obj_create(nullptr);
  addTextBox();
  addTextArea(device);
  addStatusMessage();
  addLoaderArc();

  if(!py.pythonCallMain([&py, &device](){
    eventLoop(py, device, -1);
  })){
    eventLoop(py, device, -1);
  }
  LOG(DEBUG, MAIN, "Exit\n");
  _task.join();
  return 0;
}