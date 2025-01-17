//! Model used for in parsing transactions fetched using etherscan
class EthereumTransactionModel {
  final DateTime date;
  final String hash;
  final String from;
  final String to;
  final BigInt amount;
  final int gasUsed;
  final BigInt gasPrice;
  final String contractAddress;
  final int confirmations;
  final int blockNumber;
  final String? tokenSymbol;
  final int? tokenDecimal;
  final bool isError;

  EthereumTransactionModel({
    required this.date,
    required this.hash,
    required this.from,
    required this.to,
    required this.amount,
    required this.gasUsed,
    required this.gasPrice,
    required this.contractAddress,
    required this.confirmations,
    required this.blockNumber,
    required this.tokenSymbol,
    required this.tokenDecimal,
    required this.isError,
  });

  factory EthereumTransactionModel.fromJson(Map<String, dynamic> json) => EthereumTransactionModel(
        date: DateTime.fromMillisecondsSinceEpoch(int.parse(json["timeStamp"]) * 1000),
        hash: json["hash"],
        from: json["from"],
        to: json["to"],
        amount: BigInt.parse(json["value"]),
        gasUsed: int.parse(json["gasUsed"]),
        gasPrice: BigInt.parse(json["gasPrice"]),
        contractAddress: json["contractAddress"],
        confirmations: int.parse(json["confirmations"]),
        blockNumber: int.parse(json["blockNumber"]),
        tokenSymbol: json["tokenSymbol"] ?? "ETH",
        tokenDecimal: int.tryParse(json["tokenDecimal"] ?? ""),
        isError: json["isError"] == "1",
      );
}
