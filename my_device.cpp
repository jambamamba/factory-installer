#include "my_device.h"

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

#include "json_utils.h"
#include "rendering_engine.h"
#include "ssh_session.h"
#include "scp_session.h"
#include "python_wrapper.h"

LOG_CATEGORY(MAIN, "MAIN")

MyDevice::MyDevice(const cJSON* config, std::function <bool()> event_loop)
: _ssh_session([](const std::string &title, const std::string &message){
    LOG(DEBUG, MAIN, "%s:%s\n", title.c_str(), message.c_str());
    })
, _scp_session(_ssh_session.GetSession())
, _event_loop(event_loop){
    loadFromJson(config);
}

bool 
MyDevice::openSession(){
    if(!_ssh_session.Connect(_ip, _port, _user, _password, _event_loop)){
    LOG(WARNING, MAIN, "FAILD to Connect\n");
    return false;
    }
    LOG(DEBUG, MAIN, "Connected\n");
    return true;
}

void 
MyDevice::getSerialNumberFile(const std::string &local_file){
    FILE *fp = fopen(local_file.c_str(), "wb");
    fclose(fp);
    _scp_session.ReadRemoteFile(_serialnum_file, _event_loop, [&local_file](const char *buffer, int nbytes){
        LOG(DEBUG, MAIN, "ReadRemoteFile\n");
        if(nbytes > 0){
        LOG(DEBUG, MAIN, "Read %i bytes of data from remote, saving to %s\n", nbytes, local_file.c_str());
        FILE *fp = fopen(local_file.c_str(), "a+b");
        fwrite(buffer, nbytes, 1, fp);
        fclose(fp);
        }
        return nbytes;
        }
    );
}

void 
MyDevice::putSerialNumberFile(const std::string &local_file){
    struct stat st;
    stat(local_file.c_str(), &st);
    size_t file_size = st.st_size;
    FILE *fp = fopen(local_file.c_str(), "rb");
    _scp_session.WriteRemoteFile((_serialnum_file + ".new"), file_size, _event_loop, [fp,this](char *buffer, int nbytes){
    ssize_t bytes_read = fread(buffer, 1, nbytes, fp);
    LOG(DEBUG, MAIN, "WriteRemoteFile bytes %i to file '%s'\n", bytes_read, _serialnum_file.c_str());
    return bytes_read;
    }
    );
}

void
MyDevice::runCommand(const std::string &cmd){
  _ssh_session.ExecuteRemoteCommand(cmd, _event_loop, [](const char *buffer, int nbytes){
    if(nbytes > 0){
  	  LOG(DEBUG, MAIN, "%s\n", buffer);
    }
    return true;
    }
  );
}

void 
MyDevice::loadFromJson(const cJSON* config){
    cJSON *device = cJSON_GetObjectItemCaseSensitive(config, "device");
    _ip = cJSON_GetObjectItemCaseSensitive(device, "ip")->valuestring;
    _port = intFromJsonValue(cJSON_GetObjectItemCaseSensitive(device, "port"), 65536);
    _user = cJSON_GetObjectItemCaseSensitive(device, "user")->valuestring;
    _password = cJSON_GetObjectItemCaseSensitive(device, "password")->valuestring;
    _serialnum_file = cJSON_GetObjectItemCaseSensitive(device, "serialnum_file")->valuestring;
    _download_dir = cJSON_GetObjectItemCaseSensitive(device, "download_dir")->valuestring;
}

const std::string &
MyDevice::ip() const{
    return _ip;
}