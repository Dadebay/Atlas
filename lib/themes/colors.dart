import 'dart:math';

import 'package:flutter/material.dart';

// Atlas e-ticaret sitesinin lacivert/mavi temasına göre güncellendi

// Ana renkler — Atlas navbar'ındaki koyu lacivert
const kBackgroundColor =
    Color.fromRGBO(26, 58, 108, 1.0); // #1A3A6C — ana lacivert
const kBackground2Color =
    Color.fromRGBO(186, 202, 235, 200.0); // açık mavi-mor tonu
const kBackNavbarBack = Color.fromRGBO(26, 58, 108, 200.0); // navbar arka planı
const kBackPrimary2nd =
    Color.fromRGBO(255, 255, 255, 90.0); // beyaz (değişmedi)
const kbackBlue2nd = Color.fromRGBO(26, 58, 108, 0.1); // hafif lacivert tonu
const kMagazynBol = Color.fromRGBO(
    255, 176, 58, 1); // turuncu — indirim badge'i için (değişmedi)
const kGreyText = Color.fromRGBO(92, 92, 92, 1.0); // (değişmedi)
const kGreyText2 = Color(0xFF878787);
const textcolor2 = Color.fromRGBO(92, 92, 92, 1.0);
const kIconColor = Color.fromRGBO(26, 85, 188, 1.0); // mavi ikon tonu
const kIcon2Color = Color.fromRGBO(26, 85, 188, 200.0);
const kTextColor = Color.fromRGBO(214, 229, 250, 1.0); // açık mavi metin
const kprofile1Color = Color.fromRGBO(26, 58, 108, 200.0); // lacivert
const kprofile2Color = Color.fromRGBO(236, 179, 101, 200.0); // (değişmedi)
const kprofile3Color = Color.fromRGBO(70, 130, 255, 1.0); // parlak mavi
const kprofile4Color = Color.fromRGBO(255, 81, 81, 200.0); // (değişmedi)
const kstarColor = Color.fromRGBO(255, 200, 117, 10.0); // (değişmedi)
const zmoderasiya = Color.fromRGBO(255, 176, 58, 1); // (değişmedi)
const zerror = Color.fromRGBO(255, 45, 95, 1.0); // (değişmedi)
const whitest = Color.fromRGBO(255, 255, 255, 1.0);

const List<dynamic> noUserBackground = [
  Color.fromRGBO(26, 85, 188, 1.0), // koyu mavi
  Color.fromRGBO(255, 172, 172, 1.0),
  Color.fromRGBO(255, 123, 84, 1.0),
  Color.fromRGBO(130, 100, 255, 1.0) // mor-mavi
];
var backgroundNumber = Random();

abstract class AppColors {
  static const dirtyWhiteColor = Color(0xFFF5F5F5);
  static const lightGreyColor = Color(0xFFEEEEEE);
  static const lighterGreyColor = Color(0xFFD9D9D9);
  static const greyColor = Color(0xFFCAC7C7);
  static const greyFgColor = Color(0xFF978F8F);
  static const greyBgColor = Color(0xFFF3F6F9); // hafif mavi-gri arka plan
  static const mediumGreyColor = Color(0xFF878787);
  static const dirtyGreyColor = Color(0xFFEBEBEB);
  static const dirtyGrey2Color = Color(0xFFF1F0F0);
  static const orange = Color(0xFFED9507);
  static const red = Color(0xFFE11717);
  static const purple = Color(0xFF3B5FBF); // Atlas buton mavisi
  static const pink = Color(0xFFFF004F);
  static const blackWithOpacity = Color(0x40000000);
  static const black = Color(0xFF000000);
  static const greyBlack = Color(0xFF303030);
  static const green =
      Color.fromRGBO(13, 75, 122, 1.0); // Ana lacivert (eski yeşil yerine)
  static const greenn = Color(0xFF22B241);
  static const lightGreen = Color(0x1A1A3A6C); // hafif lacivert
  static const limeGreen =
      Color(0xFFD3E4F1); // açık mavi (eski lime yeşil yerine)
  static const white = Color(0xFFFFFFFF);
}

@immutable
class ColorConstants {
  const ColorConstants._();

  // Atlas ana rengi — koyu lacivert (#1A3A6C)
  static const Color kPrimaryColor = Color(0xFF1A3A6C);
  static const Color kPrimaryColor2 = Color.fromARGB(255, 240, 10, 10);

  // Sayfa arka planı — Atlas'ın açık gri-beyaz arkaplanı
  static const Color background = Color(0xFFF4F6FA);
  static const Color fonts = Color.fromARGB(255, 11, 21, 39);

  // İkincil renk — orta mavi ton
  static const Color secondary = Color(0xFF2E5DA6);

  // Atlas buton rengi — belirgin koyu mavi
  static const Color blue = Color(0xFF1A3A6C);
  static const Color hastagtext = Color(0xFF1F55BC);

  // "В корзину" (Sepete Ekle) butonu rengi — Atlas'taki koyu lacivert buton
  static const Color kSecondaryColor = Color(0xFF1A3A6C);
  static const Color successtatus =
      Color.fromARGB(255, 118, 180, 229); // mavi başarı tonu

  static const Color kPrettyBlack = Color(0xff1A1A1A);
  static const Color kPrettyBlack2 = Color(0xFF1d1d1b);
  static const Color whiteColor = Colors.white;
  static const Color blackColor = Color(0xFF121212);
  static const Color greyColor = Colors.grey;

  // Açık mavi — kart hover ve arka plan tonları
  static const Color blueColorwithOpacity = Color(0xFFD3E4F5);
  static const Color greenColor = kSecondaryColor;

  // Lacivert açık ton — badge arka planları
  static const Color greenColorwithOpacity = Color(0xFF1A5298);
  static const Color greenColorwithOpacity2 = Color(0xFFDDE8F5);

  // İndirim badge rengi — Atlas'taki kırmızı %10 badge
  static const Color yellowColorwithOpacity = Color(0xFFE8192C);

  // "Новый" (Yeni) banner rengi — Atlas'taki bordo/kahverengi
  static const Color purpleColor = Color(0xFF8B1A1A);
  static const Color purpleColorwithOpacity = Color(0xFFF5E0E0);

  static const Color greyColorwithOpacity = Color(0xffF2F5FC);
  static const Color redColorwithOpacity = Color(0x00ff7272);
  static const Color redColor = Colors.red;

  // Premium — sarı/altın (değişmedi)
  static const Color premiumColor = Color(0xfffed42a);
}
