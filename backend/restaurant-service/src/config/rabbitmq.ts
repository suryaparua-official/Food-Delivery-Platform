import amqp from "amqplib";

let channel: amqp.Channel;

export const connectRabbitMQ = async () => {
  const url = process.env.RABBITMQ_URL!;
  let retries = 10;

  while (retries) {
    try {
      console.log("Connecting to RabbitMQ...");

      const connection = await amqp.connect(url);

      connection.on("error", (err) => {
        console.error("RabbitMQ connection error:", err.message);
      });

      connection.on("close", () => {
        console.error("RabbitMQ connection closed");
      });

      channel = await connection.createChannel();

      await channel.assertQueue(process.env.PAYMENT_QUEUE!, {
        durable: true,
      });

      await channel.assertQueue(process.env.RIDER_QUEUE!, {
        durable: true,
      });

      console.log("🐇 Connected to RabbitMQ (restaurant service)");
      return;
    } catch (err) {
      console.log("RabbitMQ not ready, retrying in 5s...");
      retries--;
      await new Promise((res) => setTimeout(res, 5000));
    }
  }

  console.error("Failed to connect to RabbitMQ after retries");
  process.exit(1);
};

export const getChannel = () => {
  if (!channel) {
    throw new Error("RabbitMQ channel not initialized");
  }
  return channel;
};
