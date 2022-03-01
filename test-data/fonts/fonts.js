/**
 * Try to fingerprint fonts from a browser.
 *
 * Original enumeration code from TorZillaPrint and released under the
 * MIT License: https://github.com/arkenfox/TZP
 * Original Unicode glyphs fingerprint code from
 * https://www.bamsoftware.com/talks/fc15-fontfp/fontfp.html#demo
 */

const fntStrA = 'mmmLLLmmmWWWwwwmmmllliii'

const fntOther = {
  android: ['Droid Sans', 'Droid Sans Mono', 'Droid Serif', 'Noto Color Emoji', 'Noto Emoji', 'Noto Kufi Arabic', 'Noto Mono', 'Noto Naskh Arabic', 'Noto Nastaliq Urdu', 'Noto Sans', 'Noto Sans Adlam', 'Noto Sans Adlam Unjoined', 'Noto Sans Anatolian Hieroglyphs', 'Noto Sans Arabic', 'Noto Sans Armenian', 'Noto Sans Avestan', 'Noto Sans Balinese', 'Noto Sans Bamum', 'Noto Sans Batak', 'Noto Sans Bengali', 'Noto Sans Brahmi', 'Noto Sans Buginese', 'Noto Sans Buhid', 'Noto Sans CJK JP', 'Noto Sans CJK KR', 'Noto Sans CJK SC', 'Noto Sans CJK SC Regular', 'Noto Sans CJK TC', 'Noto Sans Canadian Aboriginal', 'Noto Sans Carian', 'Noto Sans Chakma', 'Noto Sans Cham', 'Noto Sans Cherokee', 'Noto Sans Coptic', 'Noto Sans Cuneiform', 'Noto Sans Cypriot', 'Noto Sans Deseret', 'Noto Sans Devanagari', 'Noto Sans Display', 'Noto Sans Egyptian Hieroglyphs', 'Noto Sans Ethiopic', 'Noto Sans Georgian', 'Noto Sans Glagolitic', 'Noto Sans Gothic', 'Noto Sans Gujarati', 'Noto Sans Gurmukhi', 'Noto Sans Hanunoo', 'Noto Sans Hebrew', 'Noto Sans Imperial Aramaic', 'Noto Sans Inscriptional Pahlavi', 'Noto Sans Inscriptional Parthian', 'Noto Sans JP Regular', 'Noto Sans Javanese', 'Noto Sans KR Regular', 'Noto Sans Kaithi', 'Noto Sans Kannada', 'Noto Sans Kayah Li', 'Noto Sans Kharoshthi', 'Noto Sans Khmer', 'Noto Sans Lao', 'Noto Sans Lepcha', 'Noto Sans Limbu', 'Noto Sans Linear B', 'Noto Sans Lisu', 'Noto Sans Lycian', 'Noto Sans Lydian', 'Noto Sans Malayalam', 'Noto Sans Mandaic', 'Noto Sans Meetei Mayek', 'Noto Sans Mongolian', 'Noto Sans Mono', 'Noto Sans Myanmar', 'Noto Sans NKo', 'Noto Sans New Tai Lue', 'Noto Sans Ogham', 'Noto Sans Ol Chiki', 'Noto Sans Old Italic', 'Noto Sans Old Persian', 'Noto Sans Old South Arabian', 'Noto Sans Old Turkic', 'Noto Sans Oriya', 'Noto Sans Osage', 'Noto Sans Osmanya', 'Noto Sans Phags Pa', 'Noto Sans Phoenician', 'Noto Sans Rejang', 'Noto Sans Runic', 'Noto Sans SC Regular', 'Noto Sans Samaritan', 'Noto Sans Saurashtra', 'Noto Sans Shavian', 'Noto Sans Sinhala', 'Noto Sans Sundanese', 'Noto Sans Syloti Nagri', 'Noto Sans Symbols', 'Noto Sans Symbols2', 'Noto Sans Syriac Eastern', 'Noto Sans Syriac Estrangela', 'Noto Sans Syriac Western', 'Noto Sans TC Regular', 'Noto Sans Tagalog', 'Noto Sans Tagbanwa', 'Noto Sans Tai Le', 'Noto Sans Tai Tham', 'Noto Sans Tai Viet', 'Noto Sans Tamil', 'Noto Sans Telugu', 'Noto Sans Thaana', 'Noto Sans Thai', 'Noto Sans Tibetan', 'Noto Sans Tifinagh', 'Noto Sans Ugaritic', 'Noto Sans Vai', 'Noto Sans Yi', 'Noto Serif', 'Noto Serif Armenian', 'Noto Serif Bengali', 'Noto Serif CJK JP', 'Noto Serif CJK KR', 'Noto Serif CJK SC', 'Noto Serif CJK TC', 'Noto Serif Devanagari', 'Noto Serif Display', 'Noto Serif Ethiopic', 'Noto Serif Georgian', 'Noto Serif Gujarati', 'Noto Serif Hebrew', 'Noto Serif Kannada', 'Noto Serif Khmer', 'Noto Serif Lao', 'Noto Serif Malayalam', 'Noto Serif Myanmar', 'Noto Serif Sinhala', 'Noto Serif Tamil', 'Noto Serif Telugu', 'Noto Serif Thai', 'Roboto', 'Roboto Condensed'],
  linux: ['AR PL UKai CN', 'AR PL UKai HK', 'AR PL UKai TW', 'AR PL UKai TW MBE', 'AR PL UMing CN', 'AR PL UMing HK', 'AR PL UMing TW', 'AR PL UMing TW MBE', 'Abyssinica SIL', 'Aharoni CLM', 'AlArabiya', 'AlBattar', 'AlHor', 'AlManzomah', 'AlYarmook', 'Amiri', 'Amiri Quran', 'Amiri Quran Colored', 'Ani', 'AnjaliOldLipi', 'Arab', 'Arial', 'Arimo', 'Bitstream Charter', 'C059', 'Caladea', 'Caladings CLM', 'Cantarell', 'Cantarell Extra Bold', 'Cantarell Light', 'Cantarell Thin', 'Carlito', 'Century Schoolbook L', 'Chandas', 'Chilanka', 'Comfortaa', 'Comfortaa Light', 'Cortoba', 'Courier', 'Courier 10 Pitch', 'Courier New', 'Cousine', 'D050000L', 'David CLM', 'DejaVu Math TeX Gyre', 'DejaVu Sans', 'DejaVu Sans Condensed', 'DejaVu Sans Light', 'DejaVu Sans Mono', 'DejaVu Serif', 'DejaVu Serif Condensed', 'Dimnah', 'Dingbats', 'Droid Arabic Kufi', 'Droid Sans', 'Droid Sans Armenian', 'Droid Sans Devanagari', 'Droid Sans Ethiopic', 'Droid Sans Fallback', 'Droid Sans Georgian', 'Droid Sans Hebrew', 'Droid Sans Japanese', 'Droid Sans Tamil', 'Droid Sans Thai', 'Drugulin CLM', 'Dyuthi', 'Electron', 'Ellinia CLM', 'Ezra SIL', 'Ezra SIL SR', 'Frank Ruehl CLM', 'FreeMono', 'FreeSans', 'FreeSerif', 'Furat', 'Gargi', 'Garuda', 'Gayathri', 'Gayathri Thin', 'Georgia', 'Granada', 'Graph', 'Gubbi', 'Hadasim CLM', 'Hani', 'Haramain', 'Homa', 'Hor', 'Jamrul', 'Japan', 'Jet', 'Jomolhari', 'KacstArt', 'KacstBook', 'KacstDecorative', 'KacstDigital', 'KacstFarsi', 'KacstLetter', 'KacstNaskh', 'KacstOffice', 'KacstOne', 'KacstPen', 'KacstPoster', 'KacstQurn', 'KacstScreen', 'KacstTitle', 'KacstTitleL', 'Kalapi', 'Kalimati', 'Karumbi', 'Kayrawan', 'Keraleeyam', 'Keter YG', 'Khalid', 'Khmer OS', 'Khmer OS Battambang', 'Khmer OS Bokor', 'Khmer OS Content', 'Khmer OS Fasthand', 'Khmer OS Freehand', 'Khmer OS Metal Chrieng', 'Khmer OS Muol', 'Khmer OS Muol Light', 'Khmer OS Muol Pali', 'Khmer OS Siemreap', 'Khmer OS System', 'Kinnari', 'LKLUG', 'Laksaman', 'Liberation Mono', 'Liberation Sans', 'Liberation Sans Narrow', 'Liberation Serif', 'Likhan', 'Lohit Assamese', 'Lohit Bengali', 'Lohit Devanagari', 'Lohit Gujarati', 'Lohit Gurmukhi', 'Lohit Kannada', 'Lohit Malayalam', 'Lohit Odia', 'Lohit Tamil', 'Lohit Tamil Classical', 'Lohit Telugu', 'Loma', 'Manjari', 'Manjari Thin', 'Mashq', 'Mashq-Bold', 'Meera', 'Metal', 'Mingzat', 'Miriam CLM', 'Miriam Mono CLM', 'Mitra Mono', 'Montserrat', 'Montserrat Black', 'Montserrat ExtraBold', 'Montserrat ExtraLight', 'Montserrat Light', 'Montserrat Medium', 'Montserrat SemiBold', 'Montserrat Thin', 'Mukti Narrow', 'Mukti Narrow Bold', 'Nachlieli CLM', 'Nada', 'Nagham', 'Nakula', 'Navilu', 'Nazli', 'Nice', 'Nimbus Mono L', 'Nimbus Mono PS', 'Nimbus Roman', 'Nimbus Roman No9 L', 'Nimbus Sans', 'Nimbus Sans L', 'Nimbus Sans Narrow', 'Norasi', 'Noto Color Emoji', 'Noto Mono', 'Noto Naskh Arabic', 'Noto Sans Armenian', 'Noto Sans Bengali', 'Noto Sans Buginese', 'Noto Sans CJK HK', 'Noto Sans CJK HK Black', 'Noto Sans CJK HK DemiLight', 'Noto Sans CJK HK Light', 'Noto Sans CJK HK Medium', 'Noto Sans CJK HK Thin', 'Noto Sans CJK JP', 'Noto Sans CJK JP Black', 'Noto Sans CJK JP DemiLight', 'Noto Sans CJK JP Light', 'Noto Sans CJK JP Medium', 'Noto Sans CJK JP Thin', 'Noto Sans CJK KR', 'Noto Sans CJK KR Black', 'Noto Sans CJK KR DemiLight', 'Noto Sans CJK KR Light', 'Noto Sans CJK KR Medium', 'Noto Sans CJK KR Thin', 'Noto Sans CJK SC', 'Noto Sans CJK SC Black', 'Noto Sans CJK SC DemiLight', 'Noto Sans CJK SC Light', 'Noto Sans CJK SC Medium', 'Noto Sans CJK SC Thin', 'Noto Sans CJK TC', 'Noto Sans CJK TC Black', 'Noto Sans CJK TC DemiLight', 'Noto Sans CJK TC Light', 'Noto Sans CJK TC Medium', 'Noto Sans CJK TC Thin', 'Noto Sans Canadian Aboriginal', 'Noto Sans Cherokee', 'Noto Sans Devanagari', 'Noto Sans Ethiopic', 'Noto Sans Georgian', 'Noto Sans Gujarati', 'Noto Sans Gurmukhi', 'Noto Sans Hebrew', 'Noto Sans JP Regular', 'Noto Sans KR Regular', 'Noto Sans Kannada', 'Noto Sans Khmer', 'Noto Sans Lao', 'Noto Sans Malayalam', 'Noto Sans Mongolian', 'Noto Sans Mono CJK HK', 'Noto Sans Mono CJK JP', 'Noto Sans Mono CJK KR', 'Noto Sans Mono CJK SC', 'Noto Sans Mono CJK TC', 'Noto Sans Myanmar', 'Noto Sans Oriya', 'Noto Sans SC Regular', 'Noto Sans Sinhala', 'Noto Sans TC Regular', 'Noto Sans Tamil', 'Noto Sans Telugu', 'Noto Sans Thaana', 'Noto Sans Thai', 'Noto Sans Tibetan', 'Noto Sans Yi', 'Noto Serif Armenian', 'Noto Serif CJK JP', 'Noto Serif CJK JP Black', 'Noto Serif CJK JP ExtraLight', 'Noto Serif CJK JP Light', 'Noto Serif CJK JP Medium', 'Noto Serif CJK JP SemiBold', 'Noto Serif CJK KR', 'Noto Serif CJK KR Black', 'Noto Serif CJK KR ExtraLight', 'Noto Serif CJK KR Light', 'Noto Serif CJK KR Medium', 'Noto Serif CJK KR SemiBold', 'Noto Serif CJK SC', 'Noto Serif CJK SC Black', 'Noto Serif CJK SC ExtraLight', 'Noto Serif CJK SC Light', 'Noto Serif CJK SC Medium', 'Noto Serif CJK SC SemiBold', 'Noto Serif CJK TC', 'Noto Serif CJK TC Black', 'Noto Serif CJK TC ExtraLight', 'Noto Serif CJK TC Light', 'Noto Serif CJK TC Medium', 'Noto Serif CJK TC SemiBold', 'Noto Serif Khmer', 'Noto Serif Lao', 'Noto Serif Thai', 'Nuosu SIL', 'OpenSymbol', 'Ostorah', 'Ouhod', 'Ouhod-Bold', 'P052', 'PT Sans', 'PT Sans Narrow', 'Padauk', 'Padauk Book', 'Pagul', 'PakType Naskh Basic', 'Petra', 'Phetsarath OT', 'Pothana2000', 'Purisa', 'Rachana', 'RaghuMalayalamSans', 'Rasa', 'Rasa Light', 'Rasa Medium', 'Rasa SemiBold', 'Rasheeq', 'Rasheeq-Bold', 'Rehan', 'Rekha', 'STIX', 'STIX Two Math', 'STIX Two Text', 'Saab', 'Sahadeva', 'Salem', 'Samanata', 'Samyak Devanagari', 'Samyak Gujarati', 'Samyak Malayalam', 'Samyak Tamil', 'Sarai', 'Sawasdee', 'Scheherazade', 'Shado', 'Sharjah', 'Shofar', 'Simple CLM', 'Sindbad', 'Source Code Pro', 'Source Code Pro Black', 'Source Code Pro ExtraLight', 'Source Code Pro Light', 'Source Code Pro Medium', 'Source Code Pro Semibold', 'Stam Ashkenaz CLM', 'Stam Sefarad CLM', 'Standard Symbols L', 'Standard Symbols PS', 'Suruma', 'Symbola', 'Tarablus', 'Tholoth', 'Tibetan Machine Uni', 'Tinos', 'Titr', 'Tlwg Mono', 'Tlwg Typewriter', 'Tlwg Typist', 'Tlwg Typo', 'UKIJ 3D', 'UKIJ Basma', 'UKIJ Bom', 'UKIJ CJK', 'UKIJ Chechek', 'UKIJ Chiwer Kesme', 'UKIJ Diwani', 'UKIJ Diwani Kawak', 'UKIJ Diwani Tom', 'UKIJ Diwani Yantu', 'UKIJ Ekran', 'UKIJ Elipbe', 'UKIJ Elipbe_Chekitlik', 'UKIJ Esliye', 'UKIJ Esliye Chiwer', 'UKIJ Esliye Neqish', 'UKIJ Esliye Qara', 'UKIJ Esliye Tom', 'UKIJ Imaret', 'UKIJ Inchike', 'UKIJ Jelliy', 'UKIJ Junun', 'UKIJ Kawak', 'UKIJ Kawak 3D', 'UKIJ Kesme', 'UKIJ Kesme Tuz', 'UKIJ Kufi', 'UKIJ Kufi 3D', 'UKIJ Kufi Chiwer', 'UKIJ Kufi Gul', 'UKIJ Kufi Kawak', 'UKIJ Kufi Tar', 'UKIJ Kufi Uz', 'UKIJ Kufi Yay', 'UKIJ Kufi Yolluq', 'UKIJ Mejnun', 'UKIJ Mejnuntal', 'UKIJ Merdane', 'UKIJ Moy Qelem', 'UKIJ Nasq', 'UKIJ Nasq Zilwa', 'UKIJ Orqun Basma', 'UKIJ Orqun Yazma', 'UKIJ Orxun-Yensey', 'UKIJ Qara', 'UKIJ Qolyazma', 'UKIJ Qolyazma Tez', 'UKIJ Qolyazma Tuz', 'UKIJ Qolyazma Yantu', 'UKIJ Ruqi', 'UKIJ Saet', 'UKIJ Sulus', 'UKIJ Sulus Tom', 'UKIJ Teng', 'UKIJ Tiken', 'UKIJ Title', 'UKIJ Tor', 'UKIJ Tughra', 'UKIJ Tuz', 'UKIJ Tuz Basma', 'UKIJ Tuz Gezit', 'UKIJ Tuz Kitab', 'UKIJ Tuz Neqish', 'UKIJ Tuz Qara', 'UKIJ Tuz Tom', 'UKIJ Tuz Tor', 'UKIJ Zilwa', 'UKIJ_Mac Basma', 'UKIJ_Mac Ekran', 'URW Bookman', 'URW Bookman L', 'URW Chancery L', 'URW Gothic', 'URW Gothic L', 'URW Palladio L', 'Ubuntu', 'Ubuntu Condensed', 'Ubuntu Light', 'Ubuntu Mono', 'Ubuntu Thin', 'Umpush', 'Uroob', 'Vemana2000', 'Verdana', 'Waree', 'Yehuda CLM', 'Yrsa', 'Yrsa Light', 'Yrsa Medium', 'Yrsa SemiBold', 'Z003', 'aakar', 'mry_KacstQurn', 'ori1Uni', 'padmaa', 'padmaa-Bold.1.1', 'padmmaa', 'utkal', 'מרים', 'गार्गी', 'नालिमाटी', 'অনি Dvf', 'মিত্র', 'মুক্তি', 'মুক্তি পাতনা'],
  mac: ['American Typewriter Condensed', 'American Typewriter Condensed Light', 'American Typewriter Light', 'American Typewriter Semibold', 'Apple Braille Outline 6 Dot', 'Apple Braille Outline 8 Dot', 'Apple Braille Pinpoint 6 Dot', 'Apple Braille Pinpoint 8 Dot', 'Apple LiGothic Medium', 'Apple LiSung Light', 'Apple SD Gothic Neo Heavy', 'Apple SD Gothic Neo Light', 'Apple SD Gothic Neo Medium', 'Apple SD Gothic Neo SemiBold', 'Apple SD Gothic Neo UltraLight', 'Apple SD GothicNeo ExtraBold', 'Athelas', 'Avenir Book Oblique', 'Avenir Heavy Oblique', 'Avenir Light Oblique', 'Avenir Medium Oblique', 'Avenir Next Condensed Bold', 'Avenir Next Condensed Demi Bold', 'Avenir Next Condensed Heavy', 'Avenir Next Condensed Medium', 'Avenir Next Condensed Ultra Light', 'Avenir Roman', 'Baoli SC', 'Baoli TC', 'Baskerville SemiBold', 'Beirut', 'BiauKai', 'Big Caslon Medium', 'Bodoni 72 Book', 'Bodoni 72 Oldstyle Book', 'Bodoni 72 Smallcaps Book', 'Charcoal CY', 'Charter Roman', 'Comic Sans MS', 'Copperplate Light', 'Damascus Light', 'Damascus Medium', 'Damascus Semi Bold', 'Futura Condensed ExtraBold', 'Futura Condensed Medium', 'Futura Medium', 'Geneva CY', 'Gill Sans Light', 'Gill Sans SemiBold', 'Gill Sans UltraBold', 'GungSeo', 'Hannotate SC', 'Hannotate TC', 'HanziPen SC', 'HanziPen TC', 'HeadLineA', 'Hei', 'Heiti SC Light', 'Heiti SC Medium', 'Heiti TC Light', 'Heiti TC Medium', 'Helvetica CY Bold', 'Helvetica Light', 'Helvetica Neue Condensed Black', 'Helvetica Neue Condensed Bold', 'Helvetica Neue Light', 'Helvetica Neue Medium', 'Helvetica Neue UltraLight', 'Herculanum', 'Hiragino Kaku Gothic Pro W3', 'Hiragino Kaku Gothic Pro W6', 'Hiragino Kaku Gothic ProN', 'Hiragino Kaku Gothic ProN W3', 'Hiragino Kaku Gothic ProN W6', 'Hiragino Kaku Gothic Std W8', 'Hiragino Kaku Gothic StdN W8', 'Hiragino Maru Gothic Pro W4', 'Hiragino Mincho Pro W3', 'Hiragino Mincho Pro W6', 'Hiragino Sans CNS W3', 'Hiragino Sans CNS W6', 'Hoefler Text Black', 'Hoefler Text Ornaments', 'ITF Devanagari Book', 'ITF Devanagari Demi', 'ITF Devanagari Light', 'ITF Devanagari Marathi Book', 'ITF Devanagari Marathi Demi', 'ITF Devanagari Marathi Light', 'ITF Devanagari Marathi Medium', 'ITF Devanagari Medium', 'Iowan Old Style Black', 'Iowan Old Style Bold', 'Iowan Old Style Italic', 'Iowan Old Style Roman', 'Iowan Old Style Titling', 'Kai', 'Kaiti SC', 'Kaiti SC Black', 'Kaiti TC', 'Kaiti TC Black', 'Klee Demibold', 'Klee Medium', 'Kohinoor Bangla Light', 'Kohinoor Bangla Medium', 'Kohinoor Bangla Semibold', 'Kohinoor Devanagari Light', 'Kohinoor Devanagari Medium', 'Kohinoor Devanagari Semibold', 'Kohinoor Telugu Light', 'Kohinoor Telugu Medium', 'Kohinoor Telugu Semibold', 'Lantinghei SC Demibold', 'Lantinghei SC Extralight', 'Lantinghei SC Heavy', 'Lantinghei TC Demibold', 'Lantinghei TC Extralight', 'Lantinghei TC Heavy', 'LiHei Pro', 'LiSong Pro', 'Libian SC', 'Libian TC', 'LingWai SC Medium', 'LingWai TC Medium', 'Marion', 'Muna Black', 'Myriad Arabic', 'Myriad Arabic Black', 'Myriad Arabic Light', 'Myriad Arabic Semibold', 'Nanum Brush Script', 'Nanum Pen Script', 'NanumGothic', 'NanumGothic ExtraBold', 'NanumMyeongjo', 'NanumMyeongjo ExtraBold', 'New Peninim MT Bold Inclined', 'New Peninim MT Inclined', 'Noto Sans Javanese', 'Noto Sans Kannada', 'Noto Sans Myanmar', 'Noto Sans Oriya', 'Noto Serif Myanmar', 'Optima ExtraBlack', 'Osaka', 'Osaka-Mono', 'PCMyungjo', 'Papyrus Condensed', 'Phosphate Inline', 'Phosphate Solid', 'PilGi', 'PingFang HK Light', 'PingFang HK Medium', 'PingFang HK Semibold', 'PingFang HK Ultralight', 'PingFang SC Light', 'PingFang SC Medium', 'PingFang SC Semibold', 'PingFang SC Ultralight', 'PingFang TC Light', 'PingFang TC Medium', 'PingFang TC Semibold', 'PingFang TC Ultralight', 'STFangsong', 'STHeiti', 'STIX Two Math', 'STIX Two Text', 'STKaiti', 'STXihei', 'Seravek', 'Seravek ExtraLight', 'Seravek Light', 'Seravek Medium', 'SignPainter-HouseScript Semibold', 'Skia Black', 'Skia Condensed', 'Skia Extended', 'Skia Light', 'Snell Roundhand Black', 'Songti SC Black', 'Songti SC Light', 'Songti TC Light', 'Sukhumvit Set Light', 'Sukhumvit Set Medium', 'Sukhumvit Set Semi Bold', 'Sukhumvit Set Text', 'Superclarendon', 'Superclarendon Black', 'Superclarendon Light', 'Thonburi Light', 'Times Roman', 'Toppan Bunkyu Gothic', 'Toppan Bunkyu Gothic Demibold', 'Toppan Bunkyu Gothic Regular', 'Toppan Bunkyu Midashi Gothic Extrabold', 'Toppan Bunkyu Midashi Mincho Extrabold', 'Toppan Bunkyu Mincho', 'Toppan Bunkyu Mincho Regular', 'Tsukushi A Round Gothic', 'Tsukushi A Round Gothic Bold', 'Tsukushi A Round Gothic Regular', 'Tsukushi B Round Gothic', 'Tsukushi B Round Gothic Bold', 'Tsukushi B Round Gothic Regular', 'Waseem Light', 'Wawati SC', 'Wawati TC', 'Weibei SC Bold', 'Weibei TC Bold', 'Xingkai SC Bold', 'Xingkai SC Light', 'Xingkai TC Bold', 'Xingkai TC Light', 'YuGothic Bold', 'YuGothic Medium', 'YuKyokasho Bold', 'YuKyokasho Medium', 'YuKyokasho Yoko Bold', 'YuKyokasho Yoko Medium', 'YuMincho +36p Kana Demibold', 'YuMincho +36p Kana Extrabold', 'YuMincho +36p Kana Medium', 'YuMincho Demibold', 'YuMincho Extrabold', 'YuMincho Medium', 'Yuanti SC', 'Yuanti SC Light', 'Yuanti TC', 'Yuanti TC Light', 'Yuppy SC', 'Yuppy TC'],
  windows: ['Aharoni Bold', 'Aldhabi', 'Andalus', 'Angsana New', 'AngsanaUPC', 'Aparajita', 'Arabic Typesetting', 'Arial Nova', 'Arial Nova Cond', 'Arial Nova Cond Light', 'Arial Nova Light', 'Arial Unicode MS', 'BIZ UDGothic', 'BIZ UDMincho', 'BIZ UDMincho Medium', 'BIZ UDPGothic', 'BIZ UDPMincho', 'BIZ UDPMincho Medium', 'Batang', 'BatangChe', 'Browallia New', 'BrowalliaUPC', 'Cordia New', 'CordiaUPC', 'DFKai-SB', 'DaunPenh', 'David', 'DengXian', 'DengXian Light', 'DilleniaUPC', 'DilleniaUPC Bold', 'DokChampa', 'Dotum', 'DotumChe', 'Estrangelo Edessa', 'EucrosiaUPC', 'Euphemia', 'FangSong', 'FrankRuehl', 'FreesiaUPC', 'Gautami', 'Georgia Pro', 'Georgia Pro Black', 'Georgia Pro Cond', 'Georgia Pro Cond Black', 'Georgia Pro Cond Light', 'Georgia Pro Cond Semibold', 'Georgia Pro Light', 'Georgia Pro Semibold', 'Gill Sans Nova', 'Gill Sans Nova Cond', 'Gill Sans Nova Cond Lt', 'Gill Sans Nova Cond Ultra Bold', 'Gill Sans Nova Cond XBd', 'Gill Sans Nova Light', 'Gill Sans Nova Ultra Bold', 'Gisha', 'Gulim', 'GulimChe', 'Gungsuh', 'GungsuhChe', 'Ink Free', 'IrisUPC', 'Iskoola Pota', 'JasmineUPC', 'KaiTi', 'Kalinga', 'Kartika', 'Khmer UI', 'KodchiangUPC', 'Kokila', 'Lao UI', 'Latha', 'Leelawadee', 'Levenim MT', 'LilyUPC', 'MS Mincho', 'MS PMincho', 'Mangal', 'Meiryo', 'Meiryo UI', 'Microsoft Uighur', 'MingLiU', 'MingLiU_HKSCS', 'Miriam', 'Miriam Fixed', 'MoolBoran', 'Narkisim', 'Neue Haas Grotesk Text Pro', 'Neue Haas Grotesk Text Pro Medium', 'Nyala', 'PMingLiU', 'Plantagenet Cherokee', 'Raavi', 'Rockwell Nova', 'Rockwell Nova Cond', 'Rockwell Nova Cond Light', 'Rockwell Nova Extra Bold', 'Rockwell Nova Light Italic', 'Rockwell Nova Rockwell', 'Rod', 'Sakkal Majalla', 'Sanskrit Text', 'Segoe Pseudo', 'Shonar Bangla', 'Shruti', 'SimHei', 'Simplified Arabic', 'Simplified Arabic Fixed', 'Traditional Arabic', 'Tunga', 'UD Digi Kyokasho', 'UD Digi Kyokasho N-B', 'UD Digi Kyokasho N-R', 'UD Digi Kyokasho NK-B', 'UD Digi Kyokasho NK-R', 'UD Digi Kyokasho NP-B', 'UD Digi Kyokasho NP-R', 'Urdu Typesetting', 'Utsaah', 'Vani', 'Verdana Pro', 'Verdana Pro Black', 'Verdana Pro Cond', 'Verdana Pro Cond Black', 'Verdana Pro Cond Light', 'Verdana Pro Cond SemiBold', 'Verdana Pro Light', 'Verdana Pro SemiBold', 'Vijaya', 'Vrinda', 'Yu Mincho', 'Yu Mincho Demibold', 'Yu Mincho Light']
}
const fntBase = {
  android: [],
  linux: [],
  mac: ['Al Bayan', 'Al Nile', 'Al Tarikh', 'American Typewriter', 'Andale Mono', 'Apple Braille', 'Apple Chancery', 'Apple Color Emoji', 'Apple SD Gothic Neo', 'Apple Symbols', 'AppleGothic', 'AppleMyungjo', 'Arial', 'Arial Black', 'Arial Hebrew', 'Arial Hebrew Scholar', 'Arial Narrow', 'Arial Rounded MT Bold', 'Arial Unicode MS', 'Avenir', 'Avenir Black', 'Avenir Black Oblique', 'Avenir Book', 'Avenir Heavy', 'Avenir Light', 'Avenir Medium', 'Avenir Next', 'Avenir Next Demi Bold', 'Avenir Next Heavy', 'Avenir Next Medium', 'Avenir Next Ultra Light', 'Avenir Oblique', 'Ayuthaya', 'Baghdad', 'Bangla MN', 'Bangla Sangam MN', 'Baskerville', 'Bodoni 72', 'Bodoni 72 Oldstyle', 'Bodoni 72 Smallcaps', 'Bodoni Ornaments', 'Bradley Hand', 'Brush Script MT', 'Chalkboard', 'Chalkboard SE', 'Chalkduster', 'Charter', 'Charter Black', 'Cochin', 'Copperplate', 'Corsiva Hebrew', 'Courier', 'Courier New', 'DIN Alternate', 'DIN Condensed', 'Damascus', 'DecoType Naskh', 'Devanagari MT', 'Devanagari Sangam MN', 'Didot', 'Diwan Kufi', 'Diwan Thuluth', 'Euphemia UCAS', 'Farah', 'Farisi', 'Futura', 'GB18030 Bitmap', 'Geeza Pro', 'Geneva', 'Georgia', 'Gill Sans', 'Gujarati MT', 'Gujarati Sangam MN', 'Gurmukhi MN', 'Gurmukhi MT', 'Gurmukhi Sangam MN', 'Heiti SC', 'Heiti TC', 'Helvetica', 'Helvetica Neue', 'Hiragino Maru Gothic ProN', 'Hiragino Maru Gothic ProN W4', 'Hiragino Mincho ProN', 'Hiragino Mincho ProN W3', 'Hiragino Mincho ProN W6', 'Hiragino Sans', 'Hiragino Sans GB', 'Hiragino Sans GB W3', 'Hiragino Sans GB W6', 'Hiragino Sans W0', 'Hiragino Sans W1', 'Hiragino Sans W2', 'Hiragino Sans W3', 'Hiragino Sans W4', 'Hiragino Sans W5', 'Hiragino Sans W6', 'Hiragino Sans W7', 'Hiragino Sans W8', 'Hiragino Sans W9', 'Hoefler Text', 'ITF Devanagari', 'ITF Devanagari Marathi', 'Impact', 'InaiMathi', 'Kailasa', 'Kannada MN', 'Kannada Sangam MN', 'Kefa', 'Khmer MN', 'Khmer Sangam MN', 'Kohinoor Bangla', 'Kohinoor Devanagari', 'Kohinoor Telugu', 'Kokonor', 'Krungthep', 'KufiStandardGK', 'Lao MN', 'Lao Sangam MN', 'Lucida Grande', 'Luminari', 'Malayalam MN', 'Malayalam Sangam MN', 'Marker Felt', 'Menlo', 'Microsoft Sans Serif', 'Mishafi', 'Mishafi Gold', 'Monaco', 'Mshtakan', 'Muna', 'Myanmar MN', 'Myanmar Sangam MN', 'Nadeem', 'New Peninim MT', 'Noteworthy', 'Noto Nastaliq Urdu', 'Optima', 'Oriya MN', 'Oriya Sangam MN', 'PT Mono', 'PT Sans', 'PT Sans Caption', 'PT Sans Narrow', 'PT Serif', 'PT Serif Caption', 'Palatino', 'Papyrus', 'Phosphate', 'PingFang HK', 'PingFang SC', 'PingFang TC', 'Plantagenet Cherokee', 'Raanana', 'Rockwell', 'STIXGeneral', 'STIXIntegralsD', 'STIXIntegralsSm', 'STIXIntegralsUp', 'STIXIntegralsUpD', 'STIXIntegralsUpSm', 'STIXNonUnicode', 'STIXSizeFiveSym', 'STIXSizeFourSym', 'STIXSizeOneSym', 'STIXSizeThreeSym', 'STIXSizeTwoSym', 'STIXVariants', 'STSong', 'Sana', 'Sathu', 'Savoye LET', 'Shree Devanagari 714', 'SignPainter', 'SignPainter-HouseScript', 'Silom', 'Sinhala MN', 'Sinhala Sangam MN', 'Skia', 'Snell Roundhand', 'Songti SC', 'Songti TC', 'Sukhumvit Set', 'Symbol', 'Tahoma', 'Tamil MN', 'Tamil Sangam MN', 'Telugu MN', 'Telugu Sangam MN', 'Thonburi', 'Times', 'Times New Roman', 'Trattatello', 'Trebuchet MS', 'Verdana', 'Waseem', 'Webdings', 'Wingdings', 'Wingdings 2', 'Wingdings 3', 'Zapf Dingbats', 'Zapfino'],
  windows: ['AlternateGothic2 BT', 'Arial', 'Arial Black', 'Arial Narrow', 'Bahnschrift', 'Bahnschrift Light', 'Bahnschrift SemiBold', 'Bahnschrift SemiLight', 'Calibri', 'Calibri Light', 'Calibri Light Italic', 'Cambria', 'Cambria Math', 'Candara', 'Candara Light', 'Comic Sans MS', 'Consolas', 'Constantia', 'Corbel', 'Corbel Light', 'Courier New', 'Ebrima', 'Franklin Gothic Medium', 'Gabriola', 'Gadugi', 'Georgia', 'HoloLens MDL2 Assets', 'Impact', 'Javanese Text', 'Leelawadee UI', 'Leelawadee UI Semilight', 'Lucida Console', 'Lucida Sans Unicode', 'MS Gothic', 'MS PGothic', 'MS UI Gothic', 'MV Boli', 'Malgun Gothic', 'Malgun Gothic Semilight', 'Marlett', 'Microsoft Himalaya', 'Microsoft JhengHei', 'Microsoft JhengHei Light', 'Microsoft JhengHei UI', 'Microsoft JhengHei UI Light', 'Microsoft New Tai Lue', 'Microsoft PhagsPa', 'Microsoft Sans Serif', 'Microsoft Tai Le', 'Microsoft YaHei', 'Microsoft YaHei Light', 'Microsoft YaHei UI', 'Microsoft YaHei UI Light', 'Microsoft Yi Baiti', 'MingLiU-ExtB', 'MingLiU_HKSCS-ExtB', 'Mongolian Baiti', 'Myanmar Text', 'NSimSun', 'Nirmala UI', 'Nirmala UI Semilight', 'PMingLiU-ExtB', 'Palatino Linotype', 'Segoe MDL2 Assets', 'Segoe Print', 'Segoe Script', 'Segoe UI', 'Segoe UI Black', 'Segoe UI Emoji', 'Segoe UI Historic', 'Segoe UI Light', 'Segoe UI Semibold', 'Segoe UI Semilight', 'Segoe UI Symbol', 'SimSun', 'SimSun-ExtB', 'Sitka Banner', 'Sitka Display', 'Sitka Heading', 'Sitka Small', 'Sitka Subheading', 'Sitka Text', 'Sylfaen', 'Symbol', 'Tahoma', 'Times New Roman', 'Trebuchet MS', 'Verdana', 'Webdings', 'Wingdings', 'Yu Gothic', 'Yu Gothic Light', 'Yu Gothic Medium', 'Yu Gothic UI', 'Yu Gothic UI Light', 'Yu Gothic UI Semibold', 'Yu Gothic UI Semilight']
}
const fntAlways = {
  // note: add mozilla bundled fonts here: ToDo: make sure they are not bundled with mac/android
  android: [],
  linux: ['EmojiOne Mozilla', 'Twemoji Mozilla'],
  mac: [],
  windows: ['Courier', 'EmojiOne Mozilla', 'Helvetica', 'MS Sans Serif', 'MS Serif', 'Roman', 'Small Fonts', 'Times', 'Twemoji Mozilla', '宋体', '微软雅黑', '新細明體', '細明體', '굴림', '굴림체', '바탕', 'ＭＳ ゴシック', 'ＭＳ 明朝', 'ＭＳ Ｐゴシック', 'ＭＳ Ｐ明朝']
}
const fntTB = {
  android: [],
  linux: [],
  // mac ToDo: move bundled items to fntTBBundled
  mac: ['AppleGothic', 'Apple Color Emoji', 'Arial', 'Arial Black', 'Arial Narrow', 'Courier', 'Geneva', 'Georgia', 'Heiti TC', 'Helvetica', 'Helvetica Neue', '.Helvetica Neue DeskInterface', 'Hiragino Kaku Gothic ProN', 'Hiragino Kaku Gothic ProN W3', 'Hiragino Kaku Gothic ProN W6', 'Lucida Grande', 'Monaco', 'Noto Sans Armenian', 'Noto Sans Bengali', 'Noto Sans Buginese', 'Noto Sans Canadian Aboriginal', 'Noto Sans Cherokee', 'Noto Sans Devanagari', 'Noto Sans Ethiopic', 'Noto Sans Gujarati', 'Noto Sans Gurmukhi', 'Noto Sans Kannada', 'Noto Sans Khmer', 'Noto Sans Lao', 'Noto Sans Malayalam', 'Noto Sans Mongolian', 'Noto Sans Myanmar', 'Noto Sans Oriya', 'Noto Sans Sinhala', 'Noto Sans Tamil', 'Noto Sans Telugu', 'Noto Sans Thaana', 'Noto Sans Tibetan', 'Noto Sans Yi', 'STHeiti', 'STIX Math', 'Tahoma', 'Thonburi', 'Times', 'Times New Roman', 'Verdana'],
  windows: ['Arial', 'Arial Black', 'Arial Narrow', 'Batang', 'Cambria Math', 'Courier New', 'Euphemia', 'Gautami', 'Georgia', 'Gulim', 'GulimChe', 'Iskoola Pota', 'Kalinga', 'Kartika', 'Latha', 'Lucida Console', 'MS Gothic', 'MV Boli', 'Malgun Gothic', 'Malgun Gothic Semilight', 'Mangal', 'Meiryo', 'Meiryo UI', 'Microsoft Himalaya', 'Microsoft JhengHei', 'Microsoft JhengHei UI', 'Microsoft JhengHei UI Light', 'Microsoft YaHei', 'Microsoft YaHei Light', 'Microsoft YaHei UI', 'Microsoft YaHei UI Light', 'MingLiU', 'Nyala', 'PMingLiU', 'Plantagenet Cherokee', 'Raavi', 'Segoe UI', 'Segoe UI Black', 'Segoe UI Light', 'Segoe UI Semibold', 'Segoe UI Semilight', 'Shruti', 'SimSun', 'Sylfaen', 'Tahoma', 'Times New Roman', 'Tunga', 'Verdana', 'Vrinda', 'Yu Gothic UI', 'Yu Gothic UI Light', 'Yu Gothic UI Semibold', 'Yu Gothic UI Semilight', 'MS Mincho', 'MS PGothic', 'MS PMincho']
}
const fntTBBundled = {
  android: [],
  linux: [],
  mac: [],
  windows: ['Noto Sans Buginese', 'Noto Sans Khmer', 'Noto Sans Lao', 'Noto Sans Myanmar', 'Noto Sans Yi']
}
const fntList = [fntOther, fntBase, fntAlways, fntTB, fntTBBundled].map(lists => {
  return Object.values(lists).reduce((all, list) => all.concat(list), [])
}).reduce((all, list) => all.concat(list), [])

const createLieDetector = () => {
  // https://github.com/abrahamjuliot/creepjs
  const invalidDimensions = []
  return {
    getInvalidDimensions: () => invalidDimensions,
    compute: ({
      width,
      height,
      transformWidth,
      transformHeight,
      perspectiveWidth,
      perspectiveHeight,
      sizeWidth,
      sizeHeight,
      scrollWidth,
      scrollHeight,
      offsetWidth,
      offsetHeight,
      clientWidth,
      clientHeight
    }) => {
      const invalid = (
        width !== transformWidth ||
        width !== perspectiveWidth ||
        width !== sizeWidth ||
        width !== scrollWidth ||
        width !== offsetWidth ||
        width !== clientWidth ||
        height !== transformHeight ||
        height !== perspectiveHeight ||
        height !== sizeHeight ||
        height !== scrollHeight ||
        height !== offsetHeight ||
        height !== clientHeight
      )
      if (invalid) {
        invalidDimensions.push({
          width: [width, transformWidth, perspectiveWidth, sizeWidth, scrollWidth, offsetWidth, clientWidth],
          height: [height, transformHeight, perspectiveHeight, sizeHeight, scrollHeight, offsetHeight, clientHeight]
        })
      }
    }
  }
}

const getFonts = () => {
  /* https://github.com/abrahamjuliot/creepjs */
  const detectLies = createLieDetector()
  const doc = document // or iframe.contentWindow.document
  const id = 'font-fingerprint'
  const div = doc.createElement('div')
  div.setAttribute('id', id)
  doc.body.appendChild(div)
  doc.getElementById(id).innerHTML = `
    <style>
    #${id}-detector {
        --font: '';
        position: absolute !important;
        left: -9999px!important;
        font-size: 256px !important;
        font-style: normal !important;
        font-weight: normal !important;
        letter-spacing: normal !important;
        line-break: auto !important;
        line-height: normal !important;
        text-transform: none !important;
        text-align: left !important;
        text-decoration: none !important;
        text-shadow: none !important;
        white-space: normal !important;
        word-break: normal !important;
        word-spacing: normal !important;
        /* in order to test scrollWidth, clientWidth, etc. */
        padding: 0 !important;
        margin: 0 !important;
        /* in order to test inlineSize and blockSize */
        writing-mode: horizontal-tb !important;
        /* for transform and perspective */
        transform-origin: unset !important;
        perspective-origin: unset !important;
    }
    #${id}-detector::after {
        font-family: var(--font);
        content: '` + fntStrA + `';
    }
    </style>
    <span id="${id}-detector"></span>`

  const span = doc.getElementById(`${id}-detector`)
  const pixelsToInt = pixels => Math.round(+pixels.replace('px', ''))
  const originPixelsToInt = pixels => Math.round(2 * pixels.replace('px', ''))
  const allFonts = new Set()
  const detectedViaPixel = new Set()
  const detectedViaPixelSize = new Set()
  const detectedViaScroll = new Set()
  const detectedViaOffset = new Set()
  const detectedViaClient = new Set()
  const detectedViaTransform = new Set()
  const detectedViaPerspective = new Set()
  const baseFonts = ['monospace', 'sans-serif', 'serif']
  const style = getComputedStyle(span)

  const getDimensions = (span, style) => {
    const transform = style.transformOrigin.split(' ')
    const perspective = style.perspectiveOrigin.split(' ')
    const dimensions = {
      width: pixelsToInt(style.width),
      height: pixelsToInt(style.height),
      transformWidth: originPixelsToInt(transform[0]),
      transformHeight: originPixelsToInt(transform[1]),
      perspectiveWidth: originPixelsToInt(perspective[0]),
      perspectiveHeight: originPixelsToInt(perspective[1]),
      sizeWidth: pixelsToInt(style.inlineSize),
      sizeHeight: pixelsToInt(style.blockSize),
      scrollWidth: span.scrollWidth,
      scrollHeight: span.scrollHeight,
      offsetWidth: span.offsetWidth,
      offsetHeight: span.offsetHeight,
      clientWidth: span.clientWidth,
      clientHeight: span.clientHeight
    }
    return dimensions
  }
  const base = baseFonts.reduce((acc, font) => {
    span.style.setProperty('--font', font)
    const dimensions = getDimensions(span, style)
    detectLies.compute(dimensions)
    acc[font] = dimensions
    return acc
  }, {})

  const families = fntList.reduce((acc, font) => {
    baseFonts.forEach(baseFont => acc.push(`'${font}', ${baseFont}`))
    return acc
  }, [])

  families.forEach(family => {
    span.style.setProperty('--font', family)
    const basefont = /, (.+)/.exec(family)[1]
    const style = getComputedStyle(span)
    const dimensions = getDimensions(span, style)
    detectLies.compute(dimensions)
    const font = /'(.+)'/.exec(family)[1]
    if (dimensions.width !== base[basefont].width ||
        dimensions.height !== base[basefont].height) {
      detectedViaPixel.add(font)
      allFonts.add(font)
    }
    if (dimensions.sizeWidth !== base[basefont].sizeWidth ||
         dimensions.sizeHeight !== base[basefont].sizeHeight) {
      detectedViaPixelSize.add(font)
      allFonts.add(font)
    }
    if (dimensions.scrollWidth !== base[basefont].scrollWidth ||
        dimensions.scrollHeight !== base[basefont].scrollHeight) {
      detectedViaScroll.add(font)
      allFonts.add(font)
    }
    if (dimensions.offsetWidth !== base[basefont].offsetWidth ||
        dimensions.offsetHeight !== base[basefont].offsetHeight) {
      detectedViaOffset.add(font)
      allFonts.add(font)
    }
    if (dimensions.clientWidth !== base[basefont].clientWidth ||
        dimensions.clientHeight !== base[basefont].clientHeight) {
      detectedViaClient.add(font)
      allFonts.add(font)
    }
    if (dimensions.transformWidth !== base[basefont].transformWidth ||
        dimensions.transformHeight !== base[basefont].transformHeight) {
      detectedViaTransform.add(font)
      allFonts.add(font)
    }
    if (dimensions.perspectiveWidth !== base[basefont].perspectiveWidth ||
        dimensions.perspectiveHeight !== base[basefont].perspectiveHeight) {
      detectedViaPerspective.add(font)
      allFonts.add(font)
    }
  })

  return Array.from(allFonts.values())
}

const getUnicode = () => {
  // code based on work by David Fifield (dcf) and Serge Egelman (2015)
  //   https://www.bamsoftware.com/talks/fc15-fontfp/fontfp.html#demo

  const styles = ['default', 'sans-serif', 'serif', 'monospace', 'cursive', 'fantasy']
  const codepoints = [0x20B9, 0x2581, 0x20BA, 0xA73D, 0xFFFD, 0x20B8, 0x05C6, 0x1E9E, 0x097F, 0xF003, 0x1CDA, 0x17DD, 0x23AE, 0x0D02, 0x0B82, 0x115A, 0x2425, 0x302E, 0xA830, 0x2B06, 0x21E4, 0x20BD, 0x2C7B, 0x20B0, 0xFBEE, 0xF810, 0xFFFF, 0x007F, 0x10A0, 0x1D790, 0x0700, 0x1950, 0x3095, 0x532D, 0x061C, 0x20E3, 0xFFF9, 0x0218, 0x058F, 0x08E4, 0x09B3, 0x1C50, 0x2619]

  const stageDiv = document.getElementById('stage-div')
  const stageSpan = document.getElementById('stage-span')
  const stageSlot = document.getElementById('stage-slot')

  const results = {}
  for (const cp of codepoints) {
    results[cp] = {}
    for (const style of styles) {
      stageSlot.style.fontFamily = style === 'default' ? '' : style
      stageSlot.textContent = String.fromCodePoint(cp)
      results[cp][style] = { width: stageSpan.offsetWidth, height: stageDiv.offsetHeight }
    }
  }

  return results
}
