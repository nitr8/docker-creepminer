docker-creepminer
=================

Out-of-the-box creepMiner github build running in Ubuntu 16.04.4

Usage
-----
Start your image binding the external ports 8124 and 9001 to all interfaces to your container:
```
docker run -d -p 8124:8124 -p 9001:9001 whumphrey/creepminer
```

If you wish to use a config please map the `/config` volume to a local folder and place your `miner.confg` in there.

By default the miner loads `/usr/local/sbin/miner.config` just for testing purposes. Please use your own config file. The default config connects to the 0-100 pool by default uses the PoC Consortium wallet has no plot locations and logging is disabled as it logs to the console using Supervisor (A Process Control System)


Connecting to the creepMiner server
-------------------------------------------------------------
http://IP:8124 <-- creepminer UI
http://IP:9001 <-- supervisord UI