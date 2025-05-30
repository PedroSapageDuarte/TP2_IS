using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Web.Services;

namespace WebServicesSOAP
{
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    public class WebService1 : System.Web.Services.WebService
    {
        //Conexão à BD
        string connectionString = "Data Source=localhost\\MEIBI2025;Initial Catalog=Contabilidade; Integrated Security=True; Connect Timeout = 30; Encrypt=False; TrustServerCertificate=False; ApplicationIntent=ReadWrite; MultiSubnetFailover=False";

        //WebService para obter a peça com maior prejuízo de todas as que já foram produzidas
        [WebMethod]
        public string GetPecaMaiorPrejuizo()
        {
            //Executa esta query para conseguir obter a peça com maior "Prejuizo" da tabela "Custos_Peca"
            string query = @"SELECT TOP 1 Codigo_Peca FROM dbo.Custos_Peca ORDER BY Prejuizo DESC";
            using (SqlConnection conn = new SqlConnection(connectionString))
            using (SqlCommand cmd = new SqlCommand(query, conn))
            {
                conn.Open();
                var result = cmd.ExecuteScalar();
                //No caso de não encontrar nenhuma peça (se a bd estiver vazia) diz "Nenhuma peça encontrada"
                return result?.ToString() ?? "Nenhuma peça encontrada.";
            }
        }

        //WebService para obter os custos totais no período submetido pelo utilizador
        [WebMethod]
        public decimal ObterCustosTotaisPorPeriodo(DateTime inicio, DateTime fim)
        {
            //Executa esta query para conseguir obter a soma do "Custo_Producao" da tabela "Custos_Peca" dentro do intervalo submetido pelo user
            string query = @"SELECT SUM(Custo_Producao) 
                         FROM dbo.Custos_Peca 
                         WHERE ID_Produto IN (
                         SELECT ID_Produto 
                         FROM Producao.dbo.Produto 
                         WHERE Data_Producao BETWEEN @inicio AND @fim)";

            using (SqlConnection conn = new SqlConnection(connectionString))
            using (SqlCommand cmd = new SqlCommand(query, conn))
            {
                //Data de inicio submetida pelo utilizador
                cmd.Parameters.AddWithValue("@inicio", inicio);

                //Data de fim submetida pelo utilizador
                cmd.Parameters.AddWithValue("@fim", fim);

                conn.Open();
                var result = cmd.ExecuteScalar();
                return result != DBNull.Value ? Convert.ToDecimal(result) : 0;
            }
        }

        //WebService para obter o lucro total no período submetido pelo utilizador
        [WebMethod]
        public decimal ObterLucroTotalPorPeriodo(DateTime inicio, DateTime fim)
        {
            //Executa esta query para conseguir obter a soma do "Lucro" da tabela "Custos_Peca" dentro do intervalo submetido pelo user
            string query = @"SELECT SUM(Lucro) 
                                 FROM Custos_Peca 
                                 WHERE ID_Produto IN (
                                    SELECT ID_Produto 
                                    FROM Producao.dbo.Produto 
                                    WHERE Data_Producao BETWEEN @inicio AND @fim)";

            using (SqlConnection conn = new SqlConnection(connectionString))
            using (SqlCommand cmd = new SqlCommand(query, conn))
            {
                //Data de inicio submetida pelo utilizador
                cmd.Parameters.AddWithValue("@inicio", inicio);

                //Data de fim submetida pelo utilizador
                cmd.Parameters.AddWithValue("@fim", fim);

                conn.Open();
                var result = cmd.ExecuteScalar();
                return result != DBNull.Value ? Convert.ToDecimal(result) : 0;
            }
        }

        //WebService para obter o prejuízo por cada peça produzida no período definido pelo utilizador
        [WebMethod]
        public List<string> ObterPrejuizoTotalPorPeca(DateTime inicio, DateTime fim)
        {
            //Executa esta query para conseguir obter o "Prejuizo" de cada "Codigo_Peca" da tabela "Custos_Peca" dentro do intervalo submetido pelo user
            var resultado = new List<string>();

            string query = @"SELECT Codigo_Peca, SUM(Prejuizo) AS Total
                                 FROM Custos_Peca
                                 WHERE ID_Produto IN (
                                     SELECT ID_Produto 
                                     FROM Producao.dbo.Produto 
                                     WHERE Data_Producao BETWEEN @inicio AND @fim)
                                 GROUP BY Codigo_Peca";

            using (SqlConnection conn = new SqlConnection(connectionString))
            using (SqlCommand cmd = new SqlCommand(query, conn))
            {
                //Data de inicio submetida pelo utilizador
                cmd.Parameters.AddWithValue("@inicio", inicio);

                //Data de fim submetida pelo utilizador
                cmd.Parameters.AddWithValue("@fim", fim);

                conn.Open();
                var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    string linha = $"Peça {reader.GetString(0)}: €{reader.GetDecimal(1)}";
                    resultado.Add(linha);
                }
            }

            return resultado;
        }

        //WebService para obter os dados financeiros relativos à peça submetida pelo utilizador
        [WebMethod]
        public string ObterDadosFinanceirosPorPeca(string codigoPeca)
        {
            //Executa esta query para conseguir obter o "Codigo_Peca", "Tempo_Producao", "Custo_Producao", "Prejuizo", e "Lucro"
            //de cada "Codigo_Peca" da tabela "Custos_Peca" de acordo com o código da peça submetido pelo user
            string query = @"SELECT Codigo_Peca, Tempo_Producao, Custo_Producao, Prejuizo, Lucro 
                                 FROM Custos_Peca WHERE Codigo_Peca = @codigo";

            using (SqlConnection conn = new SqlConnection(connectionString))
            using (SqlCommand cmd = new SqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("@codigo", codigoPeca);
                conn.Open();
                var reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    return $"Peça: {reader["Codigo_Peca"]}, Tempo: {reader["Tempo_Producao"]}s, Custo: €{reader["Custo_Producao"]}, Prejuízo: €{reader["Prejuizo"]}, Lucro: €{reader["Lucro"]}";
                }
            }

            return "Peça não encontrada.";
        }
    }
}