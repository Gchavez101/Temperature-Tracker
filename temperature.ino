
//
// Declare the things that exist in our assembly code
//
extern "C" { 
   byte tempV1;
   byte tempV2;
   void setupTherm();
   void readTherm();
   void displayTemp();
}

//
// Arduino-required setup function (called once)
//
void setup()
{
  //
  // Initialize serial communications (for loop() function)
  //
  Serial.begin(9600);
  setupTherm();  // initialize thermometer
}

//
// Arduino-required loop function (called infinitely)
//
void loop()
{
  delay(2000); // 2,000 millisecs == 2 seconds
  readTherm(); // read thermometer
  displayTemp();
  Serial.print("Integer degree part: ");
  Serial.println(tempV1, DEC); // print out first byte in decimal
  Serial.print("Fractional degree part: ");
  Serial.print(tempV2, HEX); // print out the second byte in hex
  Serial.print(", ");
  Serial.println(tempV2/26, DEC); // print out decimal
  // Print out temp in F
  // F = C * 9/5 + 32
  // 10ths F = 18 * C + 320
  // 
  int temp;
  temp = 18*tempV1 + (9*tempV2)/128 + 320;
  Serial.print("Temperature is ");
  Serial.print(temp, DEC);
  Serial.println(" tenths degrees Fahrenheit.");
}

