# mnowatch

The code is under the [GNU General Public License v2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) 

These files are used in order to watch the way the Dash masternode owners vote. For more information read [here](https://www.dash.org/forum/threads/which-masternodes-voted-and-what-exactly-voted-on-various-proposals-v2.34403/) .

CURRENT MNOWATCH VERSION: 0.02

INSTALLATION

1) First [download dashd](https://www.dash.org/get-dash/) and install it into a Linux system. Then put dash-cli (along with any other script's dependencies, probably you will also need to install bc,zip and ssdeep packages) into your execution path. (Read [here](https://www.dash.org/forum/threads/which-masternodes-voted-and-what-exactly-voted-on-various-proposals-v2.34403/#post-195834) for more instructions).
2) Download the git files of mnowatch package and put them into a directory named SOME_PATH_OF_YOUR_CHOICE/bin.
3) Edit the script mnowatch.sh and change whatever is needed there (instructions inside the script)
4) Run the script. The script runs silently and lasts about 2 minutes (In an Intel Xeon 2.7 Ghz)
5) If the script ends without errors, everything is fine. The reports reside in SOME_PATH_OF_YOUR_CHOICE/httpd.
6) You may run the script manually, or you may edit the cron daemon similar to the provided crontab.example.
7) If anything goes wrong, send an OP_RETURN to the Dash address XnpT2YQaYpyh7F9twM6EtDMn1TCDCEEgNX with your message and I will contact you as soon as possible. 
Examples of sending messages to an address: [example 1](https://mydashwallet.org/Chat), [example 2](https://chainz.cryptoid.info/dash/tx.dws?6dbf28ba485ef56cf33dc0f348088f766e1302e39004bf5359161e6ba7de6ff9.htm) 

The author of the software is the owner of the Dash Address: [XnpT2YQaYpyh7F9twM6EtDMn1TCDCEEgNX](https://chainz.cryptoid.info/dash/address.dws?XnpT2YQaYpyh7F9twM6EtDMn1TCDCEEgNX.htm)
