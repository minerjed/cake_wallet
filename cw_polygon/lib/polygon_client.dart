import 'dart:convert';

import 'package:cw_ethereum/ethereum_client.dart';
import 'package:cw_polygon/polygon_transaction_model.dart';
import 'package:cw_ethereum/.secrets.g.dart' as secrets;
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';

class PolygonClient extends EthereumClient {
  @override
  Transaction createTransaction({
    required EthereumAddress from,
    required EthereumAddress to,
    required EtherAmount amount,
    EtherAmount? maxPriorityFeePerGas,
  }) {
    return Transaction(
      from: from,
      to: to,
      value: amount,
    );
  }

  @override
  Uint8List prepareSignedTransactionForSending(Uint8List signedTransaction) => signedTransaction;

  @override
  int get chainId => 137;

  @override
  Future<List<PolygonTransactionModel>> fetchTransactions(String address,
      {String? contractAddress}) async {
    try {
      final response = await httpClient.get(Uri.https("api.polygonscan.com", "/api", {
        "module": "account",
        "action": contractAddress != null ? "tokentx" : "txlist",
        if (contractAddress != null) "contractaddress": contractAddress,
        "address": address,
        "apikey": secrets.polygonScanApiKey,
      }));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300 && jsonResponse['status'] != 0) {
        return (jsonResponse['result'] as List)
            .map((e) => PolygonTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}
