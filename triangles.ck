	

	t
		r
			i
				angles

	by scott
	scottfish.me
	6/2/2015

	* * *	

(ISC License)

copyright 2015 by scott <scottfish.me>

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted, provided that the
above copyright notice and this permission notice appear in all
copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

	* * *

instructions

	requires:
		serialosc 1.2
		chuck ( http://chuck.cs.princeton.edu/release/ )
	
	quick

		install chuck, then


		1 - plug in your monome

		2 - open a terminal
			go to this folder
			run "chuck triangles.ck"

		3 - the program starts
			it looks for a monome
			and it finds a monome
			and some lights and sounds happen

		4 - press buttons to make shapes	
						
		5 - to move the shapes, tilt
			or use arrow keys on keyboard

		6 - to delete shapes, press lit keys once more

		7 - press f for faster
		    press s for slower

		    	* warning - this crashes all the time *

		8 - press c to clear

		9 - press ctrl-c-c to quit
		

	advanced
	
		make more sounds!! 
		check out "settings" below
		cmon
		do it

***********************************

			settings

***********************************/

//the type of sound to make

	SqrOsc cool;
	
	/* try replacing the above line with...

		TriOsc cool;
		SawOsc cool;
		PulseOsc cool;
		SqrOsc cool; //default

	*/

//brightness
	
	15 => int brightness; // 0 to 15

//multiplier by which speed will change

	22 => float mult;

/***********************************

		settings end

***********************************/

//osc

	"/triangles" => string prefix; 

	//initial send and receive
	OscSend xmit;
	xmit.setHost("localhost", 12002);

	OscRecv recv;
	8000 => recv.port;
	recv.listen ();

	//list devices
	xmit.startMsg("/serialosc/list", "si");
	"localhost" => xmit.addString;
	8000 => xmit.addInt;

		<<<"looking for a monome...", "">>>;

	recv.event("/serialosc/device", "ssi") @=> OscEvent discover;
	discover => now;

	string serial; string devicetype; int port;

	while(discover.nextMsg() != 0){

		discover.getString() => serial;
		discover.getString() => devicetype;
		discover.getInt() => port;

		<<<"found a", devicetype, "(", serial, ") on port", port>>>;
	}

	//connect to device 
	xmit.setHost("localhost", port);
	xmit.startMsg("/sys/port", "i");
    8000 => xmit.addInt;

	//get size
	recv.event("/sys/size", "ii") @=> OscEvent getsize;

    xmit.startMsg("/sys/info", "si");
    "localhost" => xmit.addString;	
    8000 => xmit.addInt;

	getsize => now;

	int width; int height;

	while(getsize.nextMsg() != 0){

		getsize.getInt() => width;
		getsize.getInt() => height;

		//<<<"size is", width, "by", height>>>;
	}


	//set prefix, brightness

	xmit.startMsg("/sys/prefix", "s");
	prefix => xmit.addString;

	xmit.startMsg( prefix+"/grid/led/intensity", "i");
	brightness => xmit.addInt;
		
		//<<<"brightness", brightness>>>;
    
	recv.event( prefix+"/grid/key", "iii") @=> OscEvent oe;

	//tilt business

		xmit.startMsg( prefix+"/tilt/set", "ii");
		0 => xmit.addInt;
		255 => xmit.addInt;

		recv.event( prefix+"/tilt", "iiii") @=> OscEvent te;

		int tilt[2];

// here goes

//cool => dac;

28 => int n;

0 => int countoff;

int light[width][height];
int special[width][height];

int shape[9][1][2];
int traveler[2];
float pos[2];

1 => int nowshape;		//future versions could have multiple shapes

0 => int maxp;
0 => int nowp;

clear();

intro();

KBHit kb;


<<<"", "">>>;
<<<"", "">>>;
<<<"", "">>>;
<<<"", "">>>;
<<<"t r i a n g l e s", "">>>;

spork ~sequencer();

while(true){
	while( kb.more() ){
		kb.getchar() => int kbchar;     

		//<<<kbchar>>>;

		if (kbchar == 102){		//f
			1.1 /=> mult;
			<<<"speed", 100.0/mult>>>;
			//<<<mult>>>;
		}

		if (kbchar == 115){		//s
			1.1 *=> mult;
			<<<"speed", 100.0/mult>>>;
			//<<<mult>>>;		
		}

		if (kbchar == 99){		//c
			deleteall();
			<<<"clear">>>;
		}

		if (kbchar == 67){		//right
			move (1, 0);
		}

		if (kbchar == 68){		//left
			move(-1, 0);
		}

		if (kbchar == 66){		//up
			move (0, 1);
		}

		if (kbchar == 65){		//down
			move (0, -1);
		}
	}

	while (te.nextMsg() != 0){
		te.getInt() => int n;
		te.getInt() => int x;
		te.getInt() => int y;
		te.getInt() => int z;

		(127-x) / (75 / (width)) => int changex;
		(y-127) / (75 / (height)) => int changey;
		
		if (tilt[0] != changex || tilt[1] != changey){
			changex => tilt[0];
			changey => tilt[1];

			move(changex, changey);

			//<<<changex, changey>>>;
		}
	}

	while (oe.nextMsg() != 0){
		oe.getInt() => int x;
		oe.getInt() => int y;
		oe.getInt() => int z;

		if (z == 1){
			point(x, y, z);
	    }
	}

	0.06::second => now;
}

fun void point( int x, int y, int z){
	if (z == 1){
		if (special[x][y] > 0){
			deletepoint(x, y);
		}
		else {	
			int newguy[2];		
			
			shape[nowshape] << newguy;

			1 +=> maxp;
			//<<<maxp>>>;

			x => shape[nowshape][maxp][0];
			y => shape[nowshape][maxp][1];

			updateshape(maxp);
		}
	}
}

fun void deleteall(){	
	for (maxp => int i; i >= 1; i--){
		shape[nowshape][i][0] => int x;
		shape[nowshape][i][1] => int y;		
		deletepoint(x, y);
	}
}


fun void deletepoint(int x, int y)
{
	if (special[x][y] == maxp){
		1 -=> maxp;	
		0 => special[x][y];
		led_buf(x,y,0);
	}

	else {
		for (  ( (special[x][y]) + 1 ) => int i; i <= maxp; i++){
				shape[nowshape][i][0] => shape[nowshape][i-1][0];
				shape[nowshape][i][1] => shape[nowshape][i-1][1];

			1 -=> special[shape[nowshape][i][0]][shape[nowshape][i][1]];
		}
			
		0 => special[x][y];
		led_buf(x,y,0);

		1 -=> maxp;
	}

	if (maxp == 0){
		cool =< dac;
	}

}

fun void updateshape(int start){
	for (start => int i; i <= maxp; i++){
		led_buf(shape[nowshape][i][0], shape[nowshape][i][1], 1);
		i => special[shape[nowshape][i][0]][shape[nowshape][i][1]];
	}
}

fun void move (int x, int y){
	int moveok;
	for (1 => int i; i <= maxp; i++){
		x + shape[nowshape][i][0] => int plusx;
		y + shape[nowshape][i][1] => int plusy;

		if (plusx < 0 || plusy < 0 || plusx >= width || plusy >= height){
			//deletepoint(shape[i][0], shape[i][1]);
		}

		else{
			1 +=> moveok;
		}
	}

	if (moveok == maxp){
		for (1 => int i; i <= maxp; i++){	
			0 => special[shape[nowshape][i][0]][shape[nowshape][i][1]];
			led_buf(shape[nowshape][i][0], shape[nowshape][i][1], 0);

			x +=> shape[nowshape][i][0];
			y +=> shape[nowshape][i][1];
			updateshape(1);
		}
	}
}

fun void sequencer(){
	while(true){
		if (maxp > 1){
			shape[nowshape][nowp][0] => int x;
			shape[nowshape][nowp][1] => int y;

			notepress(x, y, 1);
		
			if (nowp < maxp){
				hypot(shape[nowshape][nowp][0], shape[nowshape][nowp][1], 
				shape[nowshape][nowp+1][0], shape[nowshape][nowp+1][1]);

				notepress(x, y, 0);
				1 +=> nowp;
			}

			else {
				hypot(shape[nowshape][nowp][0], shape[nowshape][nowp][1], 
				shape[nowshape][1][0], shape[nowshape][1][1]);

				notepress (x, y, 0);
				1 => nowp;
			}
		}
		.06::second=>now;
	}
}

fun void hypot (int x1, int y1, int x2, int y2){

	distance(x1, y1, x2, y2) => float c;

	Std.abs(x2 - x1) => float a;		
	Std.abs(y2 - y1) => float b;		

	(a + b) => float ab;			

	(ab / c) => float inc;			

	inc * (a / ab) => float xinc;	//<<<"x inc", xinc>>>;
	inc * (b / ab) => float yinc;	//<<<"y inc", yinc>>>;

	if (x1 > x2){-1 *=> xinc;}
	if (y1 > y2){-1 *=> yinc;}

	x1 => pos[0];
	y1 => pos[1];

	x1 => traveler[0];
	y1 => traveler[1];

	float t;

	while (t < (c * mult)){	

		int newtraveler[2];

		inc * mult::ms => now;

		xinc +=> pos[0];	//<<<"x pos", pos[0]>>>;
		yinc +=> pos[1];	//<<<"y pos", pos[1]>>>;
	
		pos[0] $int => newtraveler[0];
		pos[1] $int => newtraveler[1];
				
		if (traveler[0] != newtraveler[0] || traveler[1] != newtraveler[1]){

			led_buf (traveler[0], traveler[1], 0);

			newtraveler[0] => traveler[0];
			newtraveler[1] => traveler[1];

			led_buf (traveler[0], traveler[1], 1);
		}

		(inc * mult) +=> t;  
		//<<<"x", traveler[0], "y", traveler[1]>>>;
		//<<<t>>>;
			
	}
	
	led_buf (traveler[0], traveler[1], 0);
}

fun float distance (int x1, int y1, int x2, int y2){
	return Math.sqrt( (Math.pow( (x2-x1),2 ) + Math.pow( (y2-y1),2) ) );
}

fun void notepress(int x, int y, int z){	
	Std.abs(y - height) => int yinv;

	(yinv * 14) + x => int k; 

	if (z == 1){
		48 -=> k;

		Math.pow(2, k/12.0) * 440.0 => float f;

		f => cool.freq;
	
		cool => dac;
	}

	if (z ==0) {
		cool =< dac;
	}
}



//intro screen
fun void intro(){
	for (0 => int r; r <= (height-1); r ++)
	{
		if (r > 0)
		{
		
			led_buf(r-1, r-1, 0);
		}
	
		led_buf(r, r, 1);
		notepress(r,r,1);

		.05::second =>now;
	}

	led_buf(height-1,height-1,0);
	notepress(height-1,height-1,0);
	
}

//led buffer
fun void led_buf (int x, int y, int s){
	if (light[x][y] != s && special[x][y] == 0){
		s => light[x][y];
		led_set(x, y, s);
    }	
}

//real led messages
fun void led_set(int x, int y, int s){

    xmit.startMsg("/triangles/grid/led/set", "iii");
    x => xmit.addInt;
    y => xmit.addInt;
    s => xmit.addInt;
}

fun void clear(){
	//for (0 => int c; c < 1; c++){
	xmit.startMsg ("/triangles/grid/led/all", "i");
        0 => xmit.addInt;
	//}
}
