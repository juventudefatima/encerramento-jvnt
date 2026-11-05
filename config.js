// ====== EDITE AQUI ======
const C = {
  supabaseUrl: "https://dchbexdpoxgnxbffpstw.supabase.co",   // ex.: https://xxxx.supabase.co  (vazio = modo demonstração)
  anonKey: "sb_publishable_8hUHO4wHs_4VVjl5e2C4JQ_6BSjCfUA",       // chave "anon public" do Supabase
  driveUrl: "https://script.google.com/macros/s/AKfycbyrTHdREE4yJCtmQJGi2n_SRCYm6cfAxyae9EyTVNbZqYgooBBaOkpEhP6l8WTwD7qxhA/exec",      // URL do Apps Script publicado (comprovantes -> Drive)
  evento: { data: "07/12/2026", hora: "[HORÁRIO]", local: "[LOCAL]" },
  pixChave: "juventude.fatima.xv@gmail.com",
  // Pix copia e cola de cada modalidade (já com o valor embutido). O QR Code está em assets/pix-40.png, pix-50.png, pix-60.png
  pixCopiaCola: { 40: "00020126640014br.gov.bcb.pix0129juventude.fatima.xv@gmail.com0209SEM VENDA520400005303986540540.005802BR5914GERADOR DE PIX6009SAO PAULO62070503***630425C5", 50: "00020126640014br.gov.bcb.pix0129juventude.fatima.xv@gmail.com0209SEM VENDA520400005303986540550.005802BR5914GERADOR DE PIX6009SAO PAULO62070503***6304BA20", 60: "00020126640014br.gov.bcb.pix0129juventude.fatima.xv@gmail.com0209SEM VENDA520400005303986540560.005802BR5914GERADOR DE PIX6009SAO PAULO62070503***63040A2E" },
  modalidades: {
    40: "Você vendeu mais de 5 tickets.",
    50: "Você vendeu menos de 5 tickets.",
    60: "Convidado(a) que não vendeu tickets."
  },
  // Textos das autorizações. Campos: {nome} {cpf} {nascimento} {telefone} {responsavel} {responsavel_cpf} {responsavel_telefone} {valor} {data} {hora} {local}
  autImagemMaior: "Eu, {nome}, CPF {cpf}, nascido(a) em {nascimento}, telefone {telefone}, autorizo o uso da minha imagem e voz, em fotos e vídeos registrados durante o encerramento da Juventude de Fátima, realizado em {data}, às {hora}, em {local}, para divulgação em redes sociais e materiais da Juventude, sem fins comerciais e sem qualquer ônus.",
  autParticipacaoMenor: "Eu, {responsavel}, CPF {responsavel_cpf}, telefone {responsavel_telefone}, responsável legal por {nome}, CPF {cpf}, nascido(a) em {nascimento}, autorizo a sua participação no encerramento da Juventude de Fátima, que acontecerá em {data}, às {hora}, em {local}. Declaro que efetuei o pagamento de R$ {valor} e que estou ciente das orientações do evento.",
  autImagemMenor: "Eu, {responsavel}, CPF {responsavel_cpf}, telefone {responsavel_telefone}, responsável legal por {nome}, CPF {cpf}, autorizo o uso da imagem e voz do(a) menor, em fotos e vídeos registrados durante o encerramento da Juventude de Fátima, realizado em {data}, às {hora}, em {local}, para divulgação em redes sociais e materiais da Juventude, sem fins comerciais e sem qualquer ônus.",
  // Só para testar sem Supabase (modo demonstração)
  demo: { "maria exemplo": { valor: 40, telefone: "(47) 99999-0000" }, "joao exemplo": { valor: 50 } }
};
