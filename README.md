docker-creepminer
=================

Out-of-the-box creepMiner github build running in Ubuntu 16.04.4

Usage
-----
Start your image binding the external ports 22, 80 and 3306 in all interfaces to your container:

	docker run -d -p 8124:8124 -p 9001:9001 whumphrey/creepminer

Config, the miner loads a default config from the container, puley for testing purouses.

If you wish to use a config please map a volume to a local folder and place your miner.confg in there.

Connecting to the creepMiner server
-------------------------------------------------------------
http://IP:8124 <-- creepminer UI
http://IP:9001 <-- supervisord UI