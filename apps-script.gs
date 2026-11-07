// Google Apps Script — recebe o comprovante e salva numa pasta do Drive.
const FOLDER_ID = "COLE_AQUI_O_ID_DA_PASTA"; // trecho final da URL da pasta no Drive

function doPost(e) {
  try {
    const d = JSON.parse(e.postData.contents);
    const blob = Utilities.newBlob(Utilities.base64Decode(d.base64), d.mime, d.nome);
    const f = DriveApp.getFolderById(FOLDER_ID).createFile(blob);
    return out({ ok: true, url: f.getUrl() });
  } catch (err) {
    return out({ ok: false });
  }
}
function out(o) {
  return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON);
}
