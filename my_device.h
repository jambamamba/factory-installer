#pragma once

#include <string>

#include "ssh_session.h"
#include "scp_session.h"

struct cJSON;
class MyDevice {

  struct SshInitializer{
    SshInitializer(){
      ssh_init();
    }
    ~SshInitializer(){
      ssh_finalize();
    }
  };
  public:
    MyDevice(const char *config, std::function <bool()> event_loop);
    bool openSession();
    void getSerialNumberFile(const std::string &local_file);
    void putSerialNumberFile(const std::string &local_file);
    void runCommand(const std::string &cmd);

  private:
    void load(const char *config);
    void loadFromJson(cJSON* json);

    SshInitializer _ssh_initializer;
    std::string _ip;
    int _port = 0;
    std::string _user;
    std::string _password;
    std::string _serialnum_file;
    SshSession _ssh_session;
    ScpSession _scp_session;
    std::function <bool()> _event_loop;
};