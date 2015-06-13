https://support.cloud.engineyard.com/hc/requests/99035

Daniel Valfre (Developer Center)
Jun 13, 1:13 AM

Hello Bill,

Looking at the log file, the error has to do with the logentries daemon not stopping correctly:

---- Begin output of /etc/init.d/logentries restart ----
STDOUT: * Stopping Logentries Agent ... [ !! ]
STDERR: * WARNING: -o/--oknodo is deprecated and will be removed in the future
 * start-stop-daemon: no matching processes found
 * ERROR: logentries failed to stop
---- End output of /etc/init.d/logentries restart ----
The problem has to do with logentries daemon having crashed the pid file at /var/run/logentries.pid was there and init thought that the daemon was running.

ip-10-140-171-13 ~ # cat /var/run/logentries.pid
13795
ip-10-140-171-13 ~ # ps aux | grep 13795
ip-10-140-171-13 ~ #
To solve it you can manually run /etc/init.d/logentries zap and click 'Apply' to trigger a Chef run across the environment.

This is an uncommon issue but can happen. Some customers have dealt with applying the aforementioned workaround while others have modified the Chef recipe to contemplate the restart issue. Having said so, probably the most suitable change is to add a monit configuration to watch over the logentries daemon pretty much like:

check process logentries
with pidfile /var/run/logentries.pid
  start program = "/etc/init.d/logentries start" with timeout 30 seconds
  stop program = "/etc/init.d/logentries stop" with timeout 30 seconds
  group logentries
Let us know how we can be of further assistance.

saludos
Daniel Valfre
EY Support

Daniel Valfre (Developer Center)
Jun 13, 2:58 AM

Hi Bill,

From looking at the Chef run in the instances, it seems that for the db and util instances the recipe restarted the logentries daemon succesfully only on the first run of the day and failed on the others for reasons that aren't evident.

So what I'll recommend to try is to either repeat the process or to modify the recipes in a way that instead of restarting the daemon they do stop; zap; start. Reckon this is a bit of trial and error, but please bear with me on it as on the other hand those logentries recipes (which we provided) are long overdue in the need of proper rewrite.

Daniel Valfre (Developer Center)
Jun 13, 6:05 AM

Hi Bill,

Finally hope we were able to dig out the root cause of this. For some unknown reason the script at /etc/init.d/logentries wasn't aware that the logentries daemon was running, and when the recipe issued a restart it errored out because, err, it was running already.
The steps I've taken, both on the db instance as well as on the util one, are outlined below:

ip-10-178-206-161 ~ # /etc/init.d/logentries status
 * status: stopped
ip-10-178-206-161 ~ # ps aux | grep le-
root      3838  0.0  0.0   8468   912 pts/0    S+   12:31   0:00 grep --colour=auto le-
root     12543  0.2  0.1 674188  9216 ?        Sl   08:50   0:31 /usr/bin/python2.7 /usr/bin/le-monitordaemon
ip-10-178-206-161 ~ # cat /var/run/logentries.pid
12543
ip-10-178-206-161 ~ # kill 12543
ip-10-178-206-161 ~ # /etc/init.d/logentries status
 * status: stopped
ip-10-178-206-161 ~ # /etc/init.d/logentries restart
 * Starting Logentries Agent ...
 * WARNING: -o/--oknodo is deprecated and will be removed in the future                                                                                               [ ok ]
ip-10-178-206-161 ~ # ps aux | grep le-
root      3976  0.2  0.1 602284  9152 ?        Sl   12:32   0:00 /usr/bin/python2.7 /usr/bin/le-monitordaemon
root      3987  0.0  0.0   8468   912 pts/0    S+   12:32   0:00 grep --colour=auto le-
ip-10-178-206-161 ~ # cat /var/run/logentries.pid
3976
ip-10-178-206-161 ~ #
So to summarize, the LogEntries recipe failing to restart the daemon can be solved according to the following:

if /etc/init.d/logentries status reports status: crashed and ps aux | grep le- doesn't show a running le-monitoringdaemon process, issue /etc/init.d/logentries status and /etc/init.d/logentries restart.

if /etc/init.d/logentries status reports status: stopped and ps aux | grep le- does show a running le-monitoringdaemon process, issue "kill cat /var/run/logentries.pid" and /etc/init.d/logentries restart.

All this shouldn't be the expected behavior so I'm opening an internal ticket for our Engineers to analyze. In the event of the issue happening again when applying Chef recipes or upgrading the env you can either follow the above steps or contacting Support referencing this ticket and we will be happy to sort it out for you.

Let us know of any question, comment, or concern that may arise, and how we can be of assistance.
