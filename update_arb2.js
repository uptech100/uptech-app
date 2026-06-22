const fs = require('fs');

const appendToArb = (filename, newKeys) => {
    const data = JSON.parse(fs.readFileSync(filename, 'utf8'));
    Object.assign(data, newKeys);
    fs.writeFileSync(filename, JSON.stringify(data, null, 4));
};

const enKeys = {
    "adminDashboard": "Admin Dashboard",
    "departments": "Departments",
    "users": "Users",
    "processes": "Processes",
    "products": "Products",
    "misReports": "MIS Reports",
    "peerRatings": "Peer Ratings"
};

const hiKeys = {
    "adminDashboard": "व्यवस्थापक डैशबोर्ड",
    "departments": "विभाग",
    "users": "उपयोगकर्ता",
    "processes": "प्रक्रियाएं",
    "products": "उत्पाद",
    "misReports": "एमआईएस रिपोर्ट",
    "peerRatings": "सहकर्मी रेटिंग"
};

const mrKeys = {
    "adminDashboard": "प्रशासक डॅशबोर्ड",
    "departments": "विभाग",
    "users": "वापरकर्ते",
    "processes": "प्रक्रिया",
    "products": "उत्पादने",
    "misReports": "एमआयएस अहवाल",
    "peerRatings": "सहकारी रेटिंग"
};

appendToArb('MOBILEAPP/lib/core/l10n/app_en.arb', enKeys);
appendToArb('MOBILEAPP/lib/core/l10n/app_hi.arb', hiKeys);
appendToArb('MOBILEAPP/lib/core/l10n/app_mr.arb', mrKeys);

console.log("ARB updated!");
