#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecure.h>
#include <SPI.h>
#include <MFRC522.h>
#include <ArduinoJson.h>

// WiFi
const char* ssid = "naim";
const char* password = "naim1526";

// Supabase
const char* functionUrl = "https://nqmzpjaiphcfrnnlxhxv.supabase.co/functions/v1/mark-attendance";
const char* anonKey = "sb_publishable_z2KxRFk5y0UQM0kNxsIJRQ_dVwFg2XN";

// RC522 Pins
#define SS_PIN  15  // D8
#define RST_PIN 0   // D3

MFRC522 rfid(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(115200);
  SPI.begin();
  rfid.PCD_Init();

  Serial.println("\n🚀 TapIn RFID System Starting...");

  // WiFi Connect
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi Connected!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
  Serial.println("📡 Ready to scan cards...\n");
}

void loop() {
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) {
    delay(100);
    return;
  }

  // UID read
  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    if (rfid.uid.uidByte[i] < 0x10) uid += "0";
    uid += String(rfid.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();

  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  Serial.print("🔖 Card UID: ");
  Serial.println(uid);

  // Send to Supabase
  sendToSupabase(uid);

  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();

  delay(3000); // 3 sec cooldown
}

void sendToSupabase(String uid) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("❌ WiFi not connected!");
    return;
  }

  WiFiClientSecure client;
  client.setInsecure(); // SSL skip for simplicity

  HTTPClient http;
  http.begin(client, functionUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("apikey", anonKey);

  String body = "{\"rfid_uid\":\"" + uid + "\"}";
  Serial.print("📤 Sending: ");
  Serial.println(body);

  int httpCode = http.POST(body);

  if (httpCode > 0) {
    String response = http.getString();
    Serial.print("📥 Response (");
    Serial.print(httpCode);
    Serial.println("):");

    // Parse JSON
    StaticJsonDocument<512> doc;
    DeserializationError error = deserializeJson(doc, response);

    if (!error) {
      bool success = doc["success"];
      const char* message = doc["message"];
      const char* student = doc["student"] | "";

      if (success) {
        Serial.println("✅ SUCCESS!");
      } else {
        Serial.println("⚠️  FAILED!");
      }
      Serial.print("👤 Student: ");
      Serial.println(student);
      Serial.print("💬 Message: ");
      Serial.println(message);
    } else {
      Serial.println(response);
    }
  } else {
    Serial.print("❌ HTTP Error: ");
    Serial.println(httpCode);
  }

  http.end();
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
}