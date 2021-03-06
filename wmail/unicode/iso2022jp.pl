#!/usr/bin/perl
# usage:
#   % iso2022jp.pl > iso2022jp.h

$perline = 8;
$unihan = "Unihan-3.2.0.txt.gz";

die "${unihan}: File not found.\n" if (!(-f $unihan));
open (SET, "gunzip -cd < ${unihan} |") or die "${unihan}: $!\n";

$ln=0; $ls = "";
while (<SET>)
{
  $line++;
  $ls = $_;
  chomp;
  s/\#.*//;
  next unless /^U\+(....)\s+kIRG_JSource\s+0\-(....)/;

  my $jcode = hex $2;
  my $ucode = hex $1;
  
  my $jcodeh = int ($jcode / 256);
  my $jcodel = $jcode % 256;

  if ($jcode < 0 || $jcode > 65535 || $ucode == 0 || 
      $jcodeh < 0x21 || $jcodeh > 0x7e || $jcodel < 0x21 || $jcodel > 0x7e) {
    print "$0: Out of JIS/Unicode code range\n";
    print sprintf("line %d: JIS 0x%04X, U+%04X\n", $line, $jcode, $ucode);
    print "> $ls";
    die;
  }

  $j2u{$jcode} = $ucode;
}

close(SET);

for ($jcode = 0x2330; $jcode < 0x237c; $jcode++) {
  $ucode = $jcode + 0xdbe0;
  $j2u{$jcode} = $ucode;
}
for ($jcode = 0x2421; $jcode < 0x2475; $jcode++) {
  $ucode = $jcode + 0xc20;
  $j2u{$jcode} = $ucode;
}
for ($jcode = 0x2521; $jcode < 0x2578; $jcode++) {
  $ucode = $jcode + 0xb80;
  $j2u{$jcode} = $ucode;
}

#  Unicode-3.2 does not make mention of JIS X 0208 marks
#  (there is no clear definitions), so manually add a
#  converting map...

$j2u{0x2121} = 0x3000;
$j2u{0x2122} = 0x3001;
$j2u{0x2123} = 0x3002;
$j2u{0x2124} = 0xff0c;
$j2u{0x2125} = 0xff0e;
$j2u{0x2126} = 0x30fb;
$j2u{0x2127} = 0xff1a;
$j2u{0x2128} = 0xff1b;
$j2u{0x2129} = 0xff1f;
$j2u{0x212a} = 0xff01;
$j2u{0x212b} = 0x309b;
$j2u{0x212c} = 0x309c;
$j2u{0x212d} = 0x00b4;
$j2u{0x212e} = 0xff40;
$j2u{0x212f} = 0x00a8;
$j2u{0x2130} = 0xff3e;
$j2u{0x2131} = 0xffe3;
$j2u{0x2132} = 0xff3f;
$j2u{0x2133} = 0x30fd;
$j2u{0x2134} = 0x30fe;
$j2u{0x2135} = 0x309d;
$j2u{0x2136} = 0x309e;
$j2u{0x2137} = 0x3003;
$j2u{0x2138} = 0x4edd;
$j2u{0x2139} = 0x3005;
$j2u{0x213a} = 0x3006;
$j2u{0x213b} = 0x3007;
$j2u{0x213c} = 0x30fc;
$j2u{0x213e} = 0x2010;
$j2u{0x213f} = 0xff0f;
$j2u{0x2140} = 0x005c;
$j2u{0x2141} = 0x301c;
$j2u{0x2142} = 0x2016;
$j2u{0x2143} = 0xff5c;
$j2u{0x2144} = 0x2026;
$j2u{0x2145} = 0x2025;
$j2u{0x2146} = 0x2018;
$j2u{0x2147} = 0x2019;
$j2u{0x2148} = 0x201c;
$j2u{0x2149} = 0x201d;
$j2u{0x214a} = 0xff08;
$j2u{0x214b} = 0xff09;
$j2u{0x214c} = 0x3014;
$j2u{0x214d} = 0x3015;
$j2u{0x214e} = 0xff3b;
$j2u{0x214f} = 0xff3d;
$j2u{0x2150} = 0xff5b;
$j2u{0x2151} = 0xff5d;
$j2u{0x2152} = 0x3008;
$j2u{0x2153} = 0x3009;
$j2u{0x2154} = 0x300a;
$j2u{0x2155} = 0x300b;
$j2u{0x2156} = 0x300c;
$j2u{0x2157} = 0x300d;
$j2u{0x2158} = 0x300e;
$j2u{0x2159} = 0x300f;
$j2u{0x215a} = 0x3010;
$j2u{0x215b} = 0x3011;
$j2u{0x215c} = 0xff0b;
$j2u{0x215d} = 0x2212;
$j2u{0x215e} = 0x00b1;
$j2u{0x215f} = 0x00d7;
$j2u{0x2160} = 0x00f7;
$j2u{0x2161} = 0xff1d;
$j2u{0x2162} = 0x2260;
$j2u{0x2163} = 0xff1c;
$j2u{0x2164} = 0xff1e;
$j2u{0x2165} = 0x2266;
$j2u{0x2166} = 0x2267;
$j2u{0x2167} = 0x221e;
$j2u{0x2168} = 0x2234;
$j2u{0x2169} = 0x2642;
$j2u{0x216a} = 0x2640;
$j2u{0x216b} = 0x00b0;
$j2u{0x216c} = 0x2032;
$j2u{0x216d} = 0x2033;
$j2u{0x216e} = 0x2103;
$j2u{0x216f} = 0xffe5;
$j2u{0x2170} = 0xff04;
$j2u{0x2171} = 0x00a2;
$j2u{0x2172} = 0x00a3;
$j2u{0x2173} = 0xff05;
$j2u{0x2174} = 0xff03;
$j2u{0x2175} = 0xff06;
$j2u{0x2176} = 0xff0a;
$j2u{0x2177} = 0xff20;
$j2u{0x2178} = 0x00a7;
$j2u{0x2179} = 0x2606;
$j2u{0x217a} = 0x2605;
$j2u{0x217b} = 0x25cb;
$j2u{0x217c} = 0x25cf;
$j2u{0x217d} = 0x25ce;
$j2u{0x217e} = 0x25c7;
$j2u{0x2221} = 0x25c6;
$j2u{0x2222} = 0x25a1;
$j2u{0x2223} = 0x25a0;
$j2u{0x2224} = 0x25b3;
$j2u{0x2225} = 0x25b2;
$j2u{0x2226} = 0x25bd;
$j2u{0x2227} = 0x25bc;
$j2u{0x2228} = 0x203b;
$j2u{0x2229} = 0x3012;
$j2u{0x222a} = 0x2192;
$j2u{0x222b} = 0x2190;
$j2u{0x222c} = 0x2191;
$j2u{0x222d} = 0x2193;
$j2u{0x222e} = 0x3013;
$j2u{0x223a} = 0x2208;
$j2u{0x223b} = 0x220b;
$j2u{0x223c} = 0x2286;
$j2u{0x223d} = 0x2287;
$j2u{0x223e} = 0x2282;
$j2u{0x223f} = 0x2283;
$j2u{0x2240} = 0x222a;
$j2u{0x2241} = 0x2229;
$j2u{0x224a} = 0x2227;
$j2u{0x224b} = 0x2228;
$j2u{0x224c} = 0x00ac;
$j2u{0x224d} = 0x21d2;
$j2u{0x224e} = 0x21d4;
$j2u{0x224f} = 0x2200;
$j2u{0x2250} = 0x2203;
$j2u{0x225c} = 0x2220;
$j2u{0x225d} = 0x22a5;
$j2u{0x225e} = 0x2312;
$j2u{0x225f} = 0x2202;
$j2u{0x2260} = 0x2207;
$j2u{0x2261} = 0x2261;
$j2u{0x2262} = 0x2252;
$j2u{0x2263} = 0x226a;
$j2u{0x2264} = 0x226b;
$j2u{0x2265} = 0x221a;
$j2u{0x2266} = 0x223d;
$j2u{0x2267} = 0x221d;
$j2u{0x2268} = 0x2235;
$j2u{0x2269} = 0x222b;
$j2u{0x226a} = 0x222c;
$j2u{0x2272} = 0x212b;
$j2u{0x2273} = 0x2030;
$j2u{0x2274} = 0x266f;
$j2u{0x2275} = 0x266d;
$j2u{0x2276} = 0x266a;
$j2u{0x2277} = 0x2020;
$j2u{0x2278} = 0x2021;
$j2u{0x2279} = 0x00b6;
$j2u{0x227e} = 0x25ef;
$j2u{0x2621} = 0x0391;
$j2u{0x2622} = 0x0392;
$j2u{0x2623} = 0x0393;
$j2u{0x2624} = 0x0394;
$j2u{0x2625} = 0x0395;
$j2u{0x2626} = 0x0396;
$j2u{0x2627} = 0x0397;
$j2u{0x2628} = 0x0398;
$j2u{0x2629} = 0x0399;
$j2u{0x262a} = 0x039a;
$j2u{0x262b} = 0x039b;
$j2u{0x262c} = 0x039c;
$j2u{0x262d} = 0x039d;
$j2u{0x262e} = 0x039e;
$j2u{0x262f} = 0x039f;
$j2u{0x2630} = 0x03a0;
$j2u{0x2631} = 0x03a1;
$j2u{0x2632} = 0x03a3;
$j2u{0x2633} = 0x03a4;
$j2u{0x2634} = 0x03a5;
$j2u{0x2635} = 0x03a6;
$j2u{0x2636} = 0x03a7;
$j2u{0x2637} = 0x03a8;
$j2u{0x2638} = 0x03a9;
$j2u{0x2641} = 0x03b1;
$j2u{0x2642} = 0x03b2;
$j2u{0x2643} = 0x03b3;
$j2u{0x2644} = 0x03b4;
$j2u{0x2645} = 0x03b5;
$j2u{0x2646} = 0x03b6;
$j2u{0x2647} = 0x03b7;
$j2u{0x2648} = 0x03b8;
$j2u{0x2649} = 0x03b9;
$j2u{0x264a} = 0x03ba;
$j2u{0x264b} = 0x03bb;
$j2u{0x264c} = 0x03bc;
$j2u{0x264d} = 0x03bd;
$j2u{0x264e} = 0x03be;
$j2u{0x264f} = 0x03bf;
$j2u{0x2650} = 0x03c0;
$j2u{0x2651} = 0x03c1;
$j2u{0x2652} = 0x03c3;
$j2u{0x2653} = 0x03c4;
$j2u{0x2654} = 0x03c5;
$j2u{0x2655} = 0x03c6;
$j2u{0x2656} = 0x03c7;
$j2u{0x2657} = 0x03c8;
$j2u{0x2658} = 0x03c9;
$j2u{0x2721} = 0x0410;
$j2u{0x2722} = 0x0411;
$j2u{0x2723} = 0x0412;
$j2u{0x2724} = 0x0413;
$j2u{0x2725} = 0x0414;
$j2u{0x2726} = 0x0415;
$j2u{0x2727} = 0x0401;
$j2u{0x2728} = 0x0416;
$j2u{0x2729} = 0x0417;
$j2u{0x272a} = 0x0418;
$j2u{0x272b} = 0x0419;
$j2u{0x272c} = 0x041a;
$j2u{0x272d} = 0x041b;
$j2u{0x272e} = 0x041c;
$j2u{0x272f} = 0x041d;
$j2u{0x2730} = 0x041e;
$j2u{0x2731} = 0x041f;
$j2u{0x2732} = 0x0420;
$j2u{0x2733} = 0x0421;
$j2u{0x2734} = 0x0422;
$j2u{0x2735} = 0x0423;
$j2u{0x2736} = 0x0424;
$j2u{0x2737} = 0x0425;
$j2u{0x2738} = 0x0426;
$j2u{0x2739} = 0x0427;
$j2u{0x273a} = 0x0428;
$j2u{0x273b} = 0x0429;
$j2u{0x273c} = 0x042a;
$j2u{0x273d} = 0x042b;
$j2u{0x273e} = 0x042c;
$j2u{0x273f} = 0x042d;
$j2u{0x2740} = 0x042e;
$j2u{0x2741} = 0x042f;
$j2u{0x2751} = 0x0430;
$j2u{0x2752} = 0x0431;
$j2u{0x2753} = 0x0432;
$j2u{0x2754} = 0x0433;
$j2u{0x2755} = 0x0434;
$j2u{0x2756} = 0x0435;
$j2u{0x2757} = 0x0451;
$j2u{0x2758} = 0x0436;
$j2u{0x2759} = 0x0437;
$j2u{0x275a} = 0x0438;
$j2u{0x275b} = 0x0439;
$j2u{0x275c} = 0x043a;
$j2u{0x275d} = 0x043b;
$j2u{0x275e} = 0x043c;
$j2u{0x275f} = 0x043d;
$j2u{0x2760} = 0x043e;
$j2u{0x2761} = 0x043f;
$j2u{0x2762} = 0x0440;
$j2u{0x2763} = 0x0441;
$j2u{0x2764} = 0x0442;
$j2u{0x2765} = 0x0443;
$j2u{0x2766} = 0x0444;
$j2u{0x2767} = 0x0445;
$j2u{0x2768} = 0x0446;
$j2u{0x2769} = 0x0447;
$j2u{0x276a} = 0x0448;
$j2u{0x276b} = 0x0449;
$j2u{0x276c} = 0x044a;
$j2u{0x276d} = 0x044b;
$j2u{0x276e} = 0x044c;
$j2u{0x276f} = 0x044d;
$j2u{0x2770} = 0x044e;
$j2u{0x2771} = 0x044f;
$j2u{0x2821} = 0x2500;
$j2u{0x2822} = 0x2502;
$j2u{0x2823} = 0x250c;
$j2u{0x2824} = 0x2510;
$j2u{0x2825} = 0x2518;
$j2u{0x2826} = 0x2514;
$j2u{0x2827} = 0x251c;
$j2u{0x2828} = 0x252c;
$j2u{0x2829} = 0x2524;
$j2u{0x282a} = 0x2534;
$j2u{0x282b} = 0x253c;
$j2u{0x282c} = 0x2501;
$j2u{0x282d} = 0x2503;
$j2u{0x282e} = 0x250f;
$j2u{0x282f} = 0x2513;
$j2u{0x2830} = 0x251b;
$j2u{0x2831} = 0x2517;
$j2u{0x2832} = 0x2523;
$j2u{0x2833} = 0x2533;
$j2u{0x2834} = 0x252b;
$j2u{0x2835} = 0x253b;
$j2u{0x2836} = 0x254b;
$j2u{0x2837} = 0x2520;
$j2u{0x2838} = 0x252f;
$j2u{0x2839} = 0x2528;
$j2u{0x283a} = 0x2537;
$j2u{0x283b} = 0x253f;
$j2u{0x283c} = 0x251d;
$j2u{0x283d} = 0x2530;
$j2u{0x283e} = 0x2525;
$j2u{0x283f} = 0x2538;
$j2u{0x2840} = 0x2542;


# make a reversal map
foreach (keys %j2u) {
  $u2j{$j2u{$_}} = $_;
}


print <<_HEADER_;
#ifndef _ISO2022JP_HDR_
#define _ISO2022JP_HDR_
/*
 * iso-2022-jp support by Norihisa Washitake <nori\@washitake.com>
 *  this patch may include some bugs, please see
 *  http://www.chimons.org/~wassy/courier/ for the latest version.
 *  $Id$
 *
 */

#if (JIS_DEBUG > 0) && defined(JIS_BUILD_APP)
#include <stdlib.h>
#include <stdio.h>
#include <wchar.h>
#include <string.h>

/* Definitions from unicode.h */
typedef wchar_t unicode_char;
struct unicode_info {
  const char *chset;
  unicode_char *(*c2u)(const char *, int *);
  char *(*u2c)(const unicode_char *, int *);
  char *(*toupper_func)(const char *, int *);
  char *(*tolower_func)(const char *, int *);
  char *(*totitle_func)(const char *, int *);
};
#else
#include "unicode.h"
#endif /* JIS_BUILD_APP */

/*
 * Some characters are unique in ISO-2022-JP character set,
 * so define them specially.
 */

#define JIS_CHAR_ESC    0x1B
#define JIS_CHAR_SO     0x0E
#define JIS_CHAR_SI     0x0F

#define JIS_TYPE_ASCII      0x0
#define JIS_TYPE_ROMAN      0x1
#define JIS_TYPE_7BITKANA   0x2
#define JIS_TYPE_8BITKANA   0x3
#define JIS_TYPE_KANJI      0x4
#define JIS_TYPE_BINARY     0x5

struct jischar_t {
  int type;
  int value;
};


_HEADER_


# first, j2u.
print "/* map: iso-2022-jp to Unicode */\n";
for ($hb=0x21; $hb<0x7f; $hb++) {
  $items = 0;
  for ($lb=0x21; $lb<0x7f; $lb++) {
    $items++ if ($j2u{$hb*256 + $lb} > 0);
  }
  if ($items > 0) {
    $items = 0;
    printf "static const unicode_char jis2uni_tbl_%02x[] = {", $hb;
    for ($lb = 0x21; $lb < 0x7f; $lb++) {
      $real = $hb*256 + $lb;
      print ", " if ($items > 0);
      print "\n  " if ($items % $perline == 0);
      $j2u{$real} = 0x003f if ($j2u{$real} == 0);
      printf("0x%04X", $j2u{$real});
      $items++;
    }
    print "\n};\n";
    $j2uout{$hb} = 1;
  }
}

print "const unicode_char * jis2uni_tbls[] = {\n";
for ($hb=0x21; $hb<0x7f; $hb++) {
  print (($hb > 0x21) ? ",\n  " : "  ");
  if ($j2uout{$hb} > 0) {
    printf "jis2uni_tbl_%02x", $hb;
  }else {
    print "NULL";
  }
}

print "\n};\n";
print "\n\n";

#next, u2j.
print "/* map : Unicode to iso-2022-jp */\n";
for ($hb=0x00; $hb<=0xff; $hb++) {
    $items = 0;
    for ($lb=0x0; $lb<=0xff; $lb++) {
        $items++ if ($u2j{$hb*256 + $lb} > 0);
    }
    if ($items > 0) {
        $items = 0;
        printf "static const unsigned uni2jis_tbl_%02x[] = {", $hb;
        for ($lb = 0x00; $lb <= 0xff; $lb++) {
            $real = $hb * 256 + $lb;
            print ", " if ($items > 0);
            print "\n  " if ($items % $perline == 0);
            $u2j{$real} = 0x003f if ($u2j{$real} == 0);
            printf("0x%04X", $u2j{$real});
            $items++;
        }
        print "\n};\n";
        $u2jout{$hb} = 1;
    }
}

print "const unsigned * uni2jis_tbls[] = {\n";
for ($hb = 0x00; $hb <= 0xff; $hb++) {
    print (($hb > 0x00) ? ",\n  " : "  ");
    if ($u2jout{$hb} > 0) {
        printf "uni2jis_tbl_%02x", $hb;
    } else {
        print "NULL";
    }
}
print "\n};\n";

print "#endif /* _ISO2022JP_HDR_ */\n";

__END__

