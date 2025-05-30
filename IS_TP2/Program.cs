using RabbitMQ.Stream.Client;
using RabbitMQ.Stream.Client.Reliable;
using RabbitMQ.Client;
using System;
using System.Text;
using System.Text.Json;
using IS_TP2;
using System.Net.Http;

class Program
{
    static async Task Main()
    {
        //Configuração da Stream - cria o sistema e garante que a stream "prod" existe
        var streamSystem = await StreamSystem.Create(new StreamSystemConfig());
        await streamSystem.CreateStream(new StreamSpec("prod") { MaxLengthBytes = 5_000_000_000 });
        //Cria o producer para enviar mensagens à stream "prod"
        var producer = await Producer.Create(new ProducerConfig(streamSystem, "prod"));

        //Configuração AMQP - prepara a conexão e o canal com RabbitMQ
        var factory = new ConnectionFactory { HostName = "localhost" };
        using var conn = await factory.CreateConnectionAsync();
        using var channel = await conn.CreateChannelAsync();
        await channel.ExchangeDeclareAsync("producao_exchange", ExchangeType.Topic);

        //Gera dados a cada 7 segundos
        while (true)
        {
            var produto = IS_TP2.NewLegacyApp.GerarProdutoAleatorio();
            var mensagem = new
            {
                data = produto.Data_Producao.ToString("yyyy-MM-dd"),
                hora = produto.Hora_Producao.ToString(@"hh\:mm\:ss"),
                codigo_peca = produto.Codigo_Peca,
                tempo_producao = produto.Tempo_Producao,
                resultado_teste = produto.Codigo_Resultado
            };

            string json = JsonSerializer.Serialize(mensagem);
            var body = Encoding.UTF8.GetBytes(json);

            //AMQP
            var routingKey = mensagem.resultado_teste == "01"
                ? "dados.producao.ok"
                : "dados.producao.falha";
            await channel.BasicPublishAsync("producao_exchange", routingKey, body);
            Console.WriteLine($"Enviado: {json}");

            //Envia para as streams
            await producer.Send(new Message(body));
            Console.WriteLine($"[STREAM] Publicado: {mensagem.codigo_peca}");

            await Task.Delay(7000);
        }
    }
}
