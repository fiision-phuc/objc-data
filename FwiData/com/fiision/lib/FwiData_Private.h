//  Project name: FwiData
//  File name   : FwiData.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 3/8/13
//  Version     : 1.20
//  --------------------------------------------------------------
//  Copyright (C) 2012, 2015 Fiision Studio.
//  All Rights Reserved.
//  --------------------------------------------------------------
//
//  Permission is hereby granted, free of charge, to any person obtaining  a  copy
//  of this software and associated documentation files (the "Software"), to  deal
//  in the Software without restriction, including without limitation  the  rights
//  to use, copy, modify, merge,  publish,  distribute,  sublicense,  and/or  sell
//  copies of the Software,  and  to  permit  persons  to  whom  the  Software  is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF  ANY  KIND,  EXPRESS  OR
//  IMPLIED, INCLUDING BUT NOT  LIMITED  TO  THE  WARRANTIES  OF  MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO  EVENT  SHALL  THE
//  AUTHORS OR COPYRIGHT HOLDERS  BE  LIABLE  FOR  ANY  CLAIM,  DAMAGES  OR  OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING  FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN  THE
//  SOFTWARE.
//
//
//  Disclaimer
//  __________
//  Although reasonable care has been taken to  ensure  the  correctness  of  this
//  software, this software should never be used in any application without proper
//  testing. Fiision Studio disclaim  all  liability  and  responsibility  to  any
//  person or entity with respect to any loss or damage caused, or alleged  to  be
//  caused, directly or indirectly, by the use of this software.

#ifndef __FWI_DATA_PRIVATE__
#define __FWI_DATA_PRIVATE__


#define Kanji_DefaultEncoding				NSShiftJISStringEncoding
#define Bytes_DefaultEncoding				NSUTF8StringEncoding

#define number_of_mask_patterns				8
#define sizeof_position_adjustment_pattern	5
#define sizeof_position_detection_pattern	7

#define table_9_index_version				0
#define table_9_index_codewords				1
#define table_9_index_ec_codewords			2
#define table_9_index_ec_blocks				6


static const NSUInteger TYPE_INFO_COORDINATES[15][2] = {
    {8, 0}, {8, 1}, {8, 2},	{8, 3}, {8, 4},
    {8, 5}, {8, 7}, {8, 8}, {7, 8}, {5, 8},
    {4, 8}, {3, 8}, {2, 8}, {1, 8}, {0, 8}
};

static const BOOL POSITION_DETECTION_PATTERN[49] = {
    YES, YES, YES, YES, YES, YES, YES,                      // 1 1 1 1 1 1 1
    YES, NO,  NO,  NO,  NO,  NO,  YES,                      // 1 0 0 0 0 0 1
    YES, NO,  YES, YES, YES, NO,  YES,                      // 1 0 1 1 1 0 1
    YES, NO,  YES, YES, YES, NO,  YES,                      // 1 0 1 1 1 0 1
    YES, NO,  YES, YES, YES, NO,  YES,                      // 1 0 1 1 1 0 1
    YES, NO,  NO,  NO,  NO,  NO,  YES,                      // 1 0 0 0 0 0 1
    YES, YES, YES, YES, YES, YES, YES                       // 1 1 1 1 1 1 1
};

static const BOOL POSITION_ADJUSTMENT_PATTERN[25] = {
    YES, YES, YES, YES, YES,                                // 1 1 1 1 1
    YES, NO,  NO,  NO,  YES,                                // 1 0 0 0 1
    YES, NO,  YES, NO,  YES,                                // 1 0 1 0 1
    YES, NO,  NO,  NO,  YES,                                // 1 0 0 0 1
    YES, YES, YES, YES, YES                                 // 1 1 1 1 1
};

static const NSInteger POSITION_ADJUSTMENT_PATTERN_COORDINATE_TABLE[40][7] = {
    {-1, -1, -1, -1,  -1,  -1,  -1},						// Version 1
    { 6, 18, -1, -1,  -1,  -1,  -1},						// Version 2
    { 6, 22, -1, -1,  -1,  -1,  -1},						// Version 3
    { 6, 26, -1, -1,  -1,  -1,  -1},						// Version 4
    { 6, 30, -1, -1,  -1,  -1,  -1},						// Version 5
    { 6, 34, -1, -1,  -1,  -1,  -1},						// Version 6
    { 6, 22, 38, -1,  -1,  -1,  -1},						// Version 7
    { 6, 24, 42, -1,  -1,  -1,  -1},						// Version 8
    { 6, 26, 46, -1,  -1,  -1,  -1},						// Version 9
    { 6, 28, 50, -1,  -1,  -1,  -1},						// Version 10
    { 6, 30, 54, -1,  -1,  -1,  -1},						// Version 11
    { 6, 32, 58, -1,  -1,  -1,  -1},						// Version 12
    { 6, 34, 62, -1,  -1,  -1,  -1},						// Version 13
    { 6, 26, 46, 66,  -1,  -1,  -1},						// Version 14
    { 6, 26, 48, 70,  -1,  -1,  -1},						// Version 15
    { 6, 26, 50, 74,  -1,  -1,  -1},						// Version 16
    { 6, 30, 54, 78,  -1,  -1,  -1},						// Version 17
    { 6, 30, 56, 82,  -1,  -1,  -1},						// Version 18
    { 6, 30, 58, 86,  -1,  -1,  -1}, 						// Version 19
    { 6, 34, 62, 90,  -1,  -1,  -1},						// Version 20
    { 6, 28, 50, 72,  94,  -1,  -1},						// Version 21
    { 6, 26, 50, 74,  98,  -1,  -1},						// Version 22
    { 6, 30, 54, 78, 102,  -1,  -1},						// Version 23
    { 6, 28, 54, 80, 106,  -1,  -1},						// Version 24
    { 6, 32, 58, 84, 110,  -1,  -1},						// Version 25
    { 6, 30, 58, 86, 114,  -1,  -1},						// Version 26
    { 6, 34, 62, 90, 118,  -1,  -1},						// Version 27
    { 6, 26, 50, 74,  98, 122,  -1},						// Version 28
    { 6, 30, 54, 78, 102, 126,  -1},						// Version 29
    { 6, 26, 52, 78, 104, 130,  -1},						// Version 30
    { 6, 30, 56, 82, 108, 134,  -1},						// Version 31
    { 6, 34, 60, 86, 112, 138,  -1},						// Version 32
    { 6, 30, 58, 86, 114, 142,  -1},						// Version 33
    { 6, 34, 62, 90, 118, 146,  -1},						// Version 34
    { 6, 30, 54, 78, 102, 126, 150},						// Version 35
    { 6, 24, 50, 76, 102, 128, 154},						// Version 36
    { 6, 28, 54, 80, 106, 132, 158},						// Version 37
    { 6, 32, 58, 84, 110, 136, 162},						// Version 38
    { 6, 26, 54, 82, 110, 138, 166},						// Version 39
    { 6, 30, 58, 86, 114, 142, 170}							// Version 40
};

//	 Version        Total           Total EC codewords                      Total EC Blocks
//                  codewords		L(00)	M(01)	Q(02)	H(03)           L	M   Q   H
static const NSUInteger TABLE_9[40][10] = {
    { 1,            26,				7,		10,		13,		17,             1,  1,  1,  1  },
    { 2,            44,				10,		16,		22,		28,             1,  1,  1,  1  },
    { 3,            70,				15,		26,		36,		44,             1,  1,  2,  2  },
    { 4,            100,			20,		36,		52,		64,             1,  2,  2,  4  },
    { 5,            134,			26,		48,		72,		88,             1,  2,  4,  4  },
    { 6,            172,			36,		64,		96,		112,            2,  4,  4,  4  },
    { 7,            196,			40,		72,		108,	130,            2,  4,  6,  5  },
    { 8,            242,			48,		88,		132,	156,            2,  4,  6,  6  },
    { 9,            292,			60,		110,	160,	192,            2,  5,  8,  8  },
    { 10,           346,			72,		130,	192,	224,            4,  5,  8,	8  },
    { 11,           404,			80,		150,	224,	264,            4,  5,  8,	11 },
    { 12,           466,			96,		176,	260,	308,            4,  8,  10,	11 },
    { 13,           532,			104,	198,	288,	352,            4,  9,  12,	16 },
    { 14,           581,			120,	216,	320,	384,            4,  9,  16,	16 },
    { 15,           655,			132,	240,	360,	432,            6,  10, 12,	18 },
    { 16,           733,			144,	280,	408,	480,            6,  10, 17,	16 },
    { 17,           815,			168,	308,	448,	532,            6,  11, 16,	19 },
    { 18,           901,			180,	338,	504,	588,            6,  13, 18,	21 },
    { 19,           991,			196,	364,	546,	650,            7,  14, 21,	25 },
    { 20,           1085,			224,	416,	600,	700,            8,  16, 20,	25 },
    { 21,           1156,			224,	442,	644,	750,            8,  17, 23,	25 },
    { 22,           1258,			252,	476,	690,	816,            9,  17, 23, 34 },
    { 23,           1364,			270,	504,	750,	900,            9,  18, 25, 30 },
    { 24,           1474,			300,	560,	810,	960,            10, 20, 27, 32 },
    { 25,           1588,			312,	588,	870,	1050,           12, 21, 29, 35 },
    { 26,           1706,			336,	644,	952,	1110,           12, 23, 34, 37 },
    { 27,           1828,			360,	700,	1020,	1200,           12, 25, 34, 40 },
    { 28,           1921,			390,	728,	1050,	1260,           13, 26, 35, 42 },
    { 29,           2051,			420,	784,	1140,	1350,           14, 28, 38, 45 },
    { 30,           2185,			450,	812,	1200,	1440,           15, 29, 40, 48 },
    { 31,           2323,			480,	868,	1290,	1530,           16, 31, 43, 51 },
    { 32,           2465,			510,	924,	1350,	1620,           17, 33, 45, 54 },
    { 33,           2611,			540,	980,	1440,	1710,           18, 35, 48, 57 },
    { 34,           2761,			570,	1036,	1530,	1800,           19, 37, 51, 60 },
    { 35,           2876,			570,	1064,	1590,	1890,           19, 38, 53, 63 },
    { 36,           3034,			600,	1120,	1680,	1980,           20, 40, 56, 66 },
    { 37,           3196,			630,	1204,	1770,	2100,           21, 43, 59, 70 },
    { 38,           3362,			660,	1260,	1860,	2220,           22, 45, 62, 74 },
    { 39,           3532,			720,	1316,	1950,	2310,           24, 47, 65, 77 },
    { 40,           3706,			750,	1372,	2040,	2430,           25, 49, 68, 81 }
};

static const uint16_t VERSION_INFO_POLY		 = 0x1f25;
static const uint16_t TYPE_INFO_POLY		 = 0x0537;
static const uint16_t TYPE_INFO_MASK_PATTERN = 0x5412;

// Define private macro functions
static inline NSString* FwiGenerateUserAgent() {
    __autoreleasing NSDictionary *bundleInfo   = [[NSBundle mainBundle] infoDictionary];
    __autoreleasing UIDevice *deviceInfo       = [UIDevice currentDevice];
    __autoreleasing NSString *bundleExecutable = [bundleInfo objectForKey:(NSString *)kCFBundleExecutableKey];
    __autoreleasing NSString *bundleIdentifier = [bundleInfo objectForKey:(NSString *)kCFBundleIdentifierKey];
    __autoreleasing NSString *bundleVersion    = [bundleInfo objectForKey:(NSString *)kCFBundleVersionKey];
    __autoreleasing NSString *systemVersion    = [deviceInfo systemVersion];
    __autoreleasing NSString *model            = [deviceInfo model];

    // Define user-agent
    return [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", (bundleExecutable ? bundleExecutable : bundleIdentifier), bundleVersion, model, systemVersion, [[UIScreen mainScreen] scale]];
}


#endif