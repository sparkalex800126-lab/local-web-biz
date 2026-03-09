// Google Apps Script — 貼到 Google Sheet 的 Apps Script 編輯器
// 功能：接收 landing page 表單資料，寫入 Google Sheets

function doPost(e) {
  try {
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    var data = JSON.parse(e.postData.contents);

    // 寫入一列：時間、姓名、電話、店家、備註
    sheet.appendRow([
      new Date(),
      data.name || '',
      data.phone || '',
      data.store || '',
      data.message || ''
    ]);

    return ContentService
      .createTextOutput(JSON.stringify({ result: 'success' }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return ContentService
      .createTextOutput(JSON.stringify({ result: 'error', error: error.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

// 初始化：建第一列欄位名稱（部署前跑一次）
function initSheet() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  sheet.getRange(1, 1, 1, 5).setValues([['時間', '姓名', '電話', '店家名稱', '備註']]);
  sheet.setFrozenRows(1);
}
