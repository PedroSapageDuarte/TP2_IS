using ClienteSOAP.SOAPws;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ClienteSOAP
{
    internal class Program
    {
        static void Main()
        {
            //Instancia e aponta a URL
            var ws = new WebService1();
            ws.Url = "https://localhost:44355/WebService1.asmx";

            bool exit = false;
            //Menu do cliente
            while (!exit)
            {
                Console.WriteLine("Escolha uma opção:");
                Console.WriteLine("1 - Peça com maior prejuízo");
                Console.WriteLine("2 - Custos totais por período");
                Console.WriteLine("3 - Lucro total por período");
                Console.WriteLine("4 - Prejuízo por peça em período");
                Console.WriteLine("5 - Dados financeiros por peça");
                Console.WriteLine("0 - Sair");
                Console.Write("Opção: ");

                string input = Console.ReadLine();
                Console.WriteLine();

                switch (input)
                {
                    //Invoca o WS de acordo com o que o utilizador pediu
                    case "1":
                        Console.WriteLine("Peça com maior prejuízo: " + ws.GetPecaMaiorPrejuizo());
                        break;

                    case "2":
                        var per1 = LerPeriodo();
                        Console.WriteLine($"Custos de {per1.inicio:d} a {per1.fim:d}: €{ws.ObterCustosTotaisPorPeriodo(per1.inicio, per1.fim):F2}");
                        break;

                    case "3":
                        var per2 = LerPeriodo();
                        Console.WriteLine($"Lucro de {per2.inicio:d} a {per2.fim:d}: €{ws.ObterLucroTotalPorPeriodo(per2.inicio, per2.fim):F2}");
                        break;

                    case "4":
                        var per3 = LerPeriodo();
                        var lista = ws.ObterPrejuizoTotalPorPeca(per3.inicio, per3.fim);
                        Console.WriteLine("Prejuízo por peça:");
                        foreach (var linha in lista) Console.WriteLine(" - " + linha);
                        break;

                    case "5":
                        Console.Write("Código da peça: ");
                        string codigo = Console.ReadLine();
                        Console.WriteLine(ws.ObterDadosFinanceirosPorPeca(codigo));
                        break;

                    case "0":
                        exit = true;
                        break;

                    default:
                        Console.WriteLine("Opção inválida.");
                        break;
                }
                Console.WriteLine();
            }
        }

        //Função para verificar o período escolhido pelo utilizador
        private static (DateTime inicio, DateTime fim) LerPeriodo()
        {
            Console.Write("Data de início (yyyy-MM-dd): ");
            DateTime inicio = DateTime.Parse(Console.ReadLine());
            Console.Write("Data de fim   (yyyy-MM-dd): ");
            DateTime fim = DateTime.Parse(Console.ReadLine());
            return (inicio, fim);
        }

    }
}
