import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kBrand = Color(0xFFFF6B57);
const kBrandDeep = Color(0xFFF25B44);
const kTeal = Color(0xFF0F766E);
const kNavy = Color(0xFF122033);
const kMuted = Color(0xFF5E6A7D);
const kText = Color(0xFF152033);
const kStroke = Color(0x140F172A);
const kPanel = Color(0xDBFFFFFF);

TextStyle displayTitle(double size) => GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.04 * size,
      color: kText,
      height: 1.02,
    );

TextStyle get eyebrowStyle => GoogleFonts.manrope(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 2.4,
      color: kBrandDeep,
    );

TextStyle get mutedBodyStyle => GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: kMuted,
      height: 1.6,
    );

TextStyle labelSmall(Color color) => GoogleFonts.manrope(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.6,
      color: color,
    );

TextStyle get sectionTitle => GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: kText,
    );

TextStyle get sectionSubtitle => GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: kMuted,
    );

ThemeData buildAppTheme() => ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.manropeTextTheme(),
      colorScheme: ColorScheme.fromSeed(seedColor: kBrand),
    );
