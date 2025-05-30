using System;

namespace IS_TP2
{
    //Nova aplicação Legada, bastante semelhante à anterior
    public class NewLegacyApp
    {
        public string Codigo_Peca { get; set; }
        public DateTime Data_Producao { get; set; }
        public TimeSpan Hora_Producao { get; set; }
        public int Tempo_Producao { get; set; }
        public string Codigo_Resultado { get; set; }

        private static readonly Random random = new Random();

        public static NewLegacyApp GerarProdutoAleatorio()
        {
            string[] tiposProduto = { "aa", "ab", "ba", "bb" };
            string tipo = tiposProduto[random.Next(tiposProduto.Length)];
            string identificador = Guid.NewGuid().ToString("N").Substring(0, 6);
            string codigoPeca = tipo + identificador;

            DateTime dataProducao = DateTime.Now.Date;
            TimeSpan horaProducao = DateTime.Now.TimeOfDay;
            int tempoProducao = random.Next(10, 51);

            string codigoResultado = GerarCodigoResultado();

            return new NewLegacyApp
            {
                Codigo_Peca = codigoPeca,
                Data_Producao = dataProducao,
                Hora_Producao = horaProducao,
                Tempo_Producao = tempoProducao,
                Codigo_Resultado = codigoResultado
            };
        }

        //Método para gerar resultado do teste
        private static string GerarCodigoResultado()
        {
            int odd = random.Next(100); //Número entre 0 e 99

            if (odd < 50)
                return "01"; //50%
            else if (odd < 65)
                return "02"; //15%
            else if (odd < 75)
                return "03"; // 10%
            else if (odd < 85)
                return "04"; // 10%
            else if (odd < 95)
                return "05"; // 10%
            else
                return "06"; // 5%
        }
    }
}
