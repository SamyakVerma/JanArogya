/// All UI strings in all 4 supported languages.
/// Never hard-code strings in widgets — always use AppStrings.of(context).
class AppStrings {
  final String langCode;

  const AppStrings(this.langCode);

  static AppStrings of(String langCode) => AppStrings(langCode);

  String _t(String en, String hi, String ta, String te) {
    switch (langCode) {
      case 'hi': return hi;
      case 'ta': return ta;
      case 'te': return te;
      default:   return en;
    }
  }

  // ── App ────────────────────────────────────────────────────────────────────
  String get appName         => 'JanArogya';
  String get appNameLocal    => _t('JanArogya', 'जनआरोग्य', 'ஜனஆரோக்யா', 'జనారోగ్య');
  String get appTagline      => _t(
    'AI-Powered Cancer Screening',
    'AI कैंसर जांच',
    'AI புற்றுநோய் திரையிடல்',
    'AI క్యాన్సర్ స్క్రీనింగ్',
  );

  // ── Navigation ─────────────────────────────────────────────────────────────
  String get navHome         => _t('Home',     'होम',      'முகப்பு',   'హోమ్');
  String get navScan         => _t('Scan',     'जांच',     'ஸ்கேன்',    'స్కాన్');
  String get navHistory      => _t('History',  'इतिहास',   'வரலாறு',    'చరిత్ర');
  String get navSettings     => _t('Settings', 'सेटिंग्स', 'அமைப்புகள்', 'సెట్టింగ్స్');

  // ── Home Screen ────────────────────────────────────────────────────────────
  String get homeGreeting    => _t(
    'Welcome to JanArogya',
    'JanArogya में आपका स्वागत है',
    'JanArogyaவிற்கு வரவேற்கிறோம்',
    'JanArogyaకి స్వాగతం',
  );
  String get homeScanNow     => _t('Scan Now',       'जांच करें',      'இப்போது ஸ்கேன் செய்',  'ఇప్పుడే స్కాన్ చేయి');
  String get homeViewHistory => _t('View History',   'इतिहास देखें',   'வரலாறு பார்க்க',       'చరిత్ర చూడు');
  String get homeCameraHint  => _t(
    'Take or upload a photo to screen for early signs',
    'जांच के लिए फोटो लें या अपलोड करें',
    'ஆரம்ப அறிகுறிகளை திரையிட புகைப்படம் எடுக்கவும்',
    'ముందస్తు సంకేతాల కోసం ఫోటో తీయండి',
  );
  String get homeHistoryHint => _t(
    'View your past scans and results',
    'अपनी पुरानी जांच और परिणाम देखें',
    'உங்கள் கடந்த கால ஸ்கேன்களை பார்க்கவும்',
    'మీ గత స్కాన్‌లు మరియు ఫలితాలను చూడండి',
  );
  String get helplineLabel   => _t(
    'Cancer Helpline',
    'कैंसर हेल्पलाइन',
    'புற்றுநோய் உதவி எண்',
    'క్యాన్సర్ హెల్ప్‌లైన్',
  );
  String get helplineNumber  => '1800-11-2345';

  // ── Scan Screen ────────────────────────────────────────────────────────────
  String get scanTitle       => _t('New Scan',            'नई जांच',           'புதிய ஸ்கேன்',        'కొత్త స్కాన్');
  String get scanTypeLabel   => _t('Scan Type',           'जांच का प्रकार',    'ஸ்கேன் வகை',          'స్కాన్ రకం');
  String get scanOral        => _t('Oral Cavity',         'मुंह की जांच',      'வாய் குழிவு',         'నోటి కుహరం');
  String get scanSkin        => _t('Skin Lesion',         'त्वचा की जांच',     'தோல் புண்',           'చర్మ గాయం');
  String get scanOther       => _t('Other',               'अन्य',              'மற்றவை',              'ఇతరాలు');
  String get scanAnalyze     => _t('Analyze',             'जांच करें',         'பகுப்பாய்வு செய்',    'విశ్లేషించు');
  String get scanInstruction => _t(
    'Take a clear, well-lit photo of the affected area. Hold steady.',
    'प्रभावित क्षेत्र की स्पष्ट, अच्छी रोशनी वाली तस्वीर लें।',
    'பாதிக்கப்பட்ட பகுதியின் தெளிவான புகைப்படம் எடுக்கவும்.',
    'ప్రభావిత ప్రాంతం యొక్క స్పష్టమైన ఫోటో తీయండి.',
  );
  String get scanAnalyzing   => _t('Analyzing...', 'जांच हो रही है...', 'பகுப்பாய்வு செய்கிறது...', 'విశ్లేషిస్తోంది...');
  String get scanRetake      => _t('Retake Photo',        'फोटो फिर लें',      'மீண்டும் புகைப்படம் எடு', 'ఫోటో తిరిగి తీయండి');
  String get scanPickImage   => _t('Choose from Gallery', 'गैलरी से चुनें',    'தொகுப்பிலிருந்து தேர்ந்தெடு', 'గ్యాలరీ నుండి ఎంచుకోండి');

  // ── Result Screen ──────────────────────────────────────────────────────────
  String get resultTitle       => _t('Screening Result',    'जांच परिणाम',     'திரையிடல் முடிவு',    'స్క్రీనింగ్ ఫలితం');
  String get resultLowRisk     => _t('LOW RISK',            'कम जोखिम',        'குறைந்த ஆபத்து',      'తక్కువ ప్రమాదం');
  String get resultHighRisk    => _t('HIGH RISK',           'अधिक जोखिम',      'அதிக ஆபத்து',        'అధిక ప్రమాదం');
  String get resultInvalid     => _t('INVALID',             'अमान्य',          'செல்லாத',             'చెల్లదు');
  String get resultConfidence  => _t('Confidence',          'विश्वसनीयता',     'நம்பகத்தன்மை',        'విశ్వాసం');
  String get resultExplanation => _t('AI Explanation',      'AI विश्लेषण',     'AI விளக்கம்',         'AI వివరణ');
  String get resultFindClinic  => _t('Find Nearest Clinic', 'नजदीकी क्लिनिक', 'அருகிலுள்ள கிளினிக்', 'దగ్గరి క్లినిక్ కనుగొనండి');
  String get resultDownload    => _t('Download Report',     'रिपोर्ट डाउनलोड', 'அறிக்கை பதிவிறக்கம்', 'నివేదిక డౌన్‌లోడ్');
  String get resultScanAgain   => _t('Scan Again',          'फिर जांचें',      'மீண்டும் ஸ்கேன் செய்', 'మళ్ళీ స்కాన్ చేయి');
  String get resultShareReport => _t('Share Report',        'रिपोर्ट शेयर करें', 'அறிக்கை பகிர்',    'నివేదిక పంచుకోండి');

  // ── History Screen ─────────────────────────────────────────────────────────
  String get historyTitle      => _t('Scan History',    'जांच इतिहास',   'ஸ்கேன் வரலாறு',      'స్కాన్ చరిత్ర');
  String get historyEmpty      => _t('No scans yet',    'अभी कोई जांच नहीं', 'இதுவரை ஸ்கேன் இல்லை', 'ఇంకా స్కాన్‌లు లేవు');
  String get historyEmptyHint  => _t(
    'Your past scans will appear here',
    'आपकी पुरानी जांच यहाँ दिखेगी',
    'உங்கள் கடந்த கால ஸ்கேன்கள் இங்கே தோன்றும்',
    'మీ గత స్కాన్‌లు ఇక్కడ కనిపిస్తాయి',
  );
  String get historyFilterAll  => _t('All',       'सभी',      'அனைத்தும்',  'అన్నీ');
  String get historyFilterLow  => _t('Low Risk',  'कम जोखिम', 'குறைந்த',    'తక్కువ');
  String get historyFilterHigh => _t('High Risk', 'अधिक जोखिम', 'அதிக',    'అధిక');
  String get historyFilterInv  => _t('Invalid',   'अमान्य',   'செல்லாத',   'చెల్లదు');

  // ── Settings Screen ────────────────────────────────────────────────────────
  String get settingsTitle       => _t('Settings',       'सेटिंग्स',      'அமைப்புகள்',      'సెట్టింగ్స్');
  String get settingsLanguage    => _t('Language',        'भाषा',           'மொழி',            'భాష');
  String get settingsTheme       => _t('Theme',           'थीम',            'தீம்',            'థీమ్');
  String get settingsThemeSystem => _t('System',          'सिस्टम',         'கணினி',           'సిస్టమ్');
  String get settingsThemeLight  => _t('Light',           'हल्का',          'ஒளி',             'లైట్');
  String get settingsThemeDark   => _t('Dark',            'गहरा',           'இருண்ட',          'డార్క్');
  String get settingsVersion     => _t('Version',         'संस्करण',        'பதிப்பு',         'వెర్షన్');
  String get settingsClearHistory => _t('Clear History',  'इतिहास साफ करें', 'வரலாற்றை அழி',  'చరిత్ర తొలగించు');
  String get settingsClearConfirm => _t(
    'This will permanently delete all scan history. Continue?',
    'यह सभी जांच इतिहास को हमेशा के लिए हटा देगा। जारी रखें?',
    'இது அனைத்து ஸ்கேன் வரலாற்றையும் நிரந்தரமாக நீக்கும். தொடர?',
    'ఇది అన్ని స్కాన్ చరిత్రను శాశ్వతంగా తొలగిస్తుంది. కొనసాగించాలా?',
  );
  String get settingsDisclaimer  => _t(
    'This app is for screening purposes only. Not a substitute for medical advice.',
    'यह ऐप केवल जांच के लिए है। चिकित्सा सलाह का विकल्प नहीं।',
    'இந்த ஆப்ப் திரையிடல் நோக்கங்களுக்காக மட்டுமே. மருத்துவ ஆலோசனைக்கு மாற்றாக இல்லை.',
    'ఈ యాప్ స్క్రీనింగ్ అవసరాలకు మాత్రమే. వైద్య సలహాకు ప్రత్యామ్నాయం కాదు.',
  );

  // ── Disclaimer ─────────────────────────────────────────────────────────────
  String get disclaimer => _t(
    'This is an AI screening tool, not a medical diagnosis. Please consult a qualified doctor.',
    'यह एक AI स्क्रीनिंग टूल है, कोई डॉक्टरी निदान नहीं। कृपया किसी योग्य डॉक्टर से मिलें।',
    'இது ஒரு AI திரையிடல் கருவி, மருத்துவ நோயறிதல் அல்ல. தயவுசெய்து ஒரு தகுதிவாய்ந்த மருத்துவரை அணுகவும்.',
    'ఇది ఒక AI స్క్రీనింగ్ సాధనం, వైద్య నిర్ధారణ కాదు. దయచేసి అర్హత గల వైద్యుడిని సంప్రదించండి.',
  );

  // ── Errors ─────────────────────────────────────────────────────────────────
  String get errorGeneric      => _t('Something went wrong. Please try again.',
    'कुछ गलत हुआ। कृपया दोबारा कोशिश करें।',
    'ஏதோ தவறானது. மீண்டும் முயற்சிக்கவும்.',
    'ఏదో తప్పు జరిగింది. దయచేసి మళ్ళీ ప్రయత్నించండి.');
  String get errorNoImage      => _t('Please take or select a photo first.',
    'कृपया पहले एक फोटो लें या चुनें।',
    'முதலில் ஒரு புகைப்படம் எடுக்கவும் அல்லது தேர்ந்தெடுக்கவும்.',
    'దయచేసి ముందుగా ఒక ఫోటో తీయండి లేదా ఎంచుకోండి.');
  String get errorBackend      => _t('Backend unavailable. Using on-device AI.',
    'बैकएंड उपलब्ध नहीं। ऑन-डिवाइस AI उपयोग।',
    'பின்தள சேவை கிடைக்கவில்லை. சாதன AI பயன்படுத்தப்படுகிறது.',
    'బ్యాకెండ్ అందుబాటులో లేదు. ఆన్-డివైస్ AI ఉపయోగిస్తున్నారు.');
  String get errorPdfFailed    => _t('Could not generate report. Please try again.',
    'रिपोर्ट तैयार नहीं हो सकी। कृपया दोबारा कोशिश करें।',
    'அறிக்கை உருவாக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    'నివేదిక రూపొందించడం సాధ్యం కాలేదు. దయచేసి మళ్ళీ ప్రయత్నించండి.');

  // ── Loading ─────────────────────────────────────────────────────────────────
  String get loadingAnalyzing  => _t('Analyzing your image...',
    'आपकी तस्वीर की जांच हो रही है...',
    'உங்கள் படம் பகுப்பாய்வு செய்யப்படுகிறது...',
    'మీ చిత్రాన్ని విశ్లేషిస్తోంది...');
  String get loadingReport     => _t('Generating report...',
    'रिपोर्ट तैयार हो रही है...',
    'அறிக்கை உருவாக்கப்படுகிறது...',
    'నివేదిక రూపొందిస్తోంది...');

  // ── Actions ─────────────────────────────────────────────────────────────────
  String get actionCancel  => _t('Cancel', 'रद्द करें', 'ரத்து செய்',    'రద్దు చేయి');
  String get actionConfirm => _t('Confirm', 'पुष्टि करें', 'உறுதிப்படுத்து', 'నిర్ధారించు');
  String get actionOk      => _t('OK',     'ठीक है',    'சரி',           'సరే');

  // ── Splash Screen ──────────────────────────────────────────────────────────
  String get splashTagline => _t(
    'Early detection saves lives',
    'जल्दी जांच से जीवन बचता है',
    'ஆரம்ப கண்டறிதல் உயிர்களை காப்பாற்றுகிறது',
    'ముందస్తు గుర్తింపు జీవితాలను కాపాడుతుంది',
  );

  // ── TTS language codes ─────────────────────────────────────────────────────
  String get ttsLangCode => switch (langCode) {
    'hi' => 'hi-IN',
    'ta' => 'ta-IN',
    'te' => 'te-IN',
    _    => 'en-US',
  };

  // ── Language display names ─────────────────────────────────────────────────
  static const Map<String, String> langNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
  };

  static const List<String> supportedLangs = ['en', 'hi', 'ta', 'te'];

  // ── Navigation (chat) ──────────────────────────────────────────────────────
  String get navChat => _t('Health Chat', 'स्वास्थ्य चैट', 'சுகாதார அரட்டை', 'ఆరోగ్య చాట్');

  // ── Chat Screen ────────────────────────────────────────────────────────────
  String get chatTitle       => _t('Health Assistant',       'स्वास्थ्य सहायक',       'சுகாதார உதவியாளர்',       'ఆరోగ్య సహాయకుడు');
  String get chatHint        => _t('Ask a health question…', 'स्वास्थ्य प्रश्न पूछें…', 'சுகாதார கேள்வி கேளுங்கள்…', 'ఆరోగ్య ప్రశ్న అడగండి…');
  String get chatWelcome     => _t(
    'Hello! I\'m your JanArogya Health Assistant. Ask me anything about your symptoms, health concerns, or when to see a doctor.',
    'नमस्ते! मैं आपका JanArogya स्वास्थ्य सहायक हूं। लक्षण, स्वास्थ्य चिंताएं, या डॉक्टर कब मिलें — कुछ भी पूछें।',
    'வணக்கம்! நான் உங்கள் JanArogya சுகாதார உதவியாளர். அறிகுறிகள், சுகாதார கவலைகள் பற்றி எதையும் கேளுங்கள்.',
    'నమస్కారం! నేను మీ JanArogya ఆరోగ్య సహాయకుడిని. లక్షణాలు, ఆరోగ్య సమస్యలు గురించి ఏదైనా అడగండి.',
  );
  String get chatThinking    => _t('Thinking…', 'सोच रहा हूं…', 'யோசிக்கிறேன்…', 'ఆలోచిస్తున్నాను…');
  String get chatDisclaimer  => _t(
    'AI assistant for general guidance only. Not a substitute for medical advice.',
    'केवल सामान्य मार्गदर्शन के लिए AI सहायक। चिकित्सा सलाह का विकल्प नहीं।',
    'பொது வழிகாட்டுதலுக்கு மட்டுமே AI உதவியாளர். மருத்துவ ஆலோசனைக்கு மாற்றாக இல்லை.',
    'సాధారణ మార్గదర్శకత్వం కోసం మాత్రమే AI సహాయకుడు. వైద్య సలహాకు ప్రత్యామ్నాయం కాదు.',
  );
  String get chatSuggestion1 => _t('What are early warning signs?', 'शुरुआती चेतावनी के संकेत क्या हैं?', 'ஆரம்ப எச்சரிக்கை அறிகுறிகள் என்ன?', 'ముందస్తు హెచ్చరిక సంకేతాలు ఏమిటి?');
  String get chatSuggestion2 => _t('When should I see a doctor?', 'डॉक्टर से कब मिलना चाहिए?', 'எப்போது மருத்துவரை சந்திக்க வேண்டும்?', 'వైద్యుడిని ఎప్పుడు చూడాలి?');
  String get chatSuggestion3 => _t('How to do self examination?', 'स्व-परीक्षण कैसे करें?', 'சுய பரிசோதனை எப்படி செய்வது?', 'స్వ-పరీక్ష ఎలా చేయాలి?');
  String get chatClear       => _t('Clear chat', 'चैट साफ करें', 'அரட்டையை அழி', 'చాట్ తొలగించు');

  // ── Dynamic questions ──────────────────────────────────────────────────────
  String get questionsLoading => _t(
    'Analyzing your photo to generate questions…',
    'प्रश्न बनाने के लिए तस्वीर का विश्लेषण हो रहा है…',
    'கேள்விகளை உருவாக்க புகைப்படம் பகுப்பாய்வு செய்யப்படுகிறது…',
    'ప్రశ్నలు రూపొందించడానికి ఫోటో విశ్లేషించబడుతోంది…',
  );

  // ── TTS ────────────────────────────────────────────────────────────────────
  String get ttsListen => _t('Listen', 'सुनें', 'கேளுங்கள்', 'వినండి');
  String get ttsStop   => _t('Stop',   'रोकें', 'நிறுத்து',  'ఆపు');

  // ── Patient Info Screen ────────────────────────────────────────────────────
  String get patientTitle      => _t('Who is this scan for?', 'यह जांच किसके लिए है?', 'இந்த ஸ்கேன் யாருக்கானது?', 'ఈ స్కాన్ ఎవరి కోసం?');
  String get patientMyself     => _t('Myself',          'मेरे लिए',        'என்னை',          'నా కోసం');
  String get patientMyselfSub  => _t('Use my saved details', 'मेरी सहेजी जानकारी', 'என் சேமித்த விவரங்கள்', 'నా సేవ్ వివరాలు');
  String get patientSomeoneElse    => _t('Someone Else',    'किसी और के लिए', 'வேறொருவர்',     'వేరే వ్యక్తి కోసం');
  String get patientSomeoneElseSub => _t('Enter their details', 'उनकी जानकारी भरें', 'அவர்களின் விவரங்களை உள்ளிடவும்', 'వారి వివరాలు నమోదు చేయండి');
  String get patientName       => _t('Full Name',        'पूरा नाम',        'முழு பெயர்',      'పూర్తి పేరు');
  String get patientAge        => _t('Age',              'आयु',             'வயது',            'వయసు');
  String get patientGender     => _t('Gender',           'लिंग',            'பாலினம்',         'లింగం');
  String get patientPhone      => _t('Phone (optional)', 'फोन (वैकल्पिक)', 'தொலைபேசி (விரும்பினால்)', 'ఫోన్ (ఐచ్ఛికం)');
  String get patientContinue   => _t('Continue',         'जारी रखें',       'தொடரவும்',        'కొనసాగించు');
  String get patientSaveInfo   => _t('Save my details for future scans', 'भविष्य की जांच के लिए मेरी जानकारी सहेजें', 'எதிர்கால ஸ்கேன்களுக்கு என் விவரங்களை சேமிக்கவும்', 'భవిష్యత్ స్కాన్‌ల కోసం నా వివరాలు సేవ్ చేయి');
  String get patientEditSaved  => _t('Edit saved details', 'सहेजी जानकारी बदलें', 'சேமித்த விவரங்களை திருத்து', 'సేవ్ వివరాలు సవరించు');
  String get patientNameRequired => _t('Please enter a name', 'कृपया नाम भरें', 'பெயரை உள்ளிடவும்', 'దయచేసి పేరు నమోదు చేయండి');
  String get patientAgeRequired  => _t('Please enter age', 'कृपया आयु भरें', 'வயதை உள்ளிடவும்', 'దయచేసి వయసు నమోదు చేయండి');
  String get patientMale       => _t('Male',   'पुरुष', 'ஆண்', 'పురుషుడు');
  String get patientFemale     => _t('Female', 'महिला', 'பெண்', 'స్త్రీ');
  String get patientOther      => _t('Other',  'अन्य',  'மற்றவை', 'ఇతరాలు');
}
