using System;

namespace TP1_Prod
{
    public class Pecas
    {
        public int ID_Produto { get; set; }
        public string CodigoPeca { get; set; }
        public DateTime DataProducao { get; set; }
        public TimeSpan HoraProducao { get; set; }
        public int TempoProducao { get; set; }
        public string CodigoResultado { get; set; }
        public DateTime DataTeste { get; set; }
        
        //NOVO
        //Se quisermos expor custos:
        public decimal? CustoProducao { get; set; }
        public decimal? Lucro { get; set; }
        public decimal? Prejuizo { get; set; }
    }
}
