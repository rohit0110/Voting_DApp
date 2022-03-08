import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Client httpClient;
  late Web3Client ethClient;

  final String myAddress = "0x5F7AD94Cd3303FF07F2B1239463ceF94f2c81217";

  final String blockchainUrl =
      "https://rinkeby.infura.io/v3/8f3a5e9d44c4436da85b4d4149186b09";

  var totalVotesA;
  var totalVotesB;

  @override
  void initState() {
    httpClient = Client();
    ethClient = Web3Client(blockchainUrl, httpClient);
    getTotalVotes();
    super.initState();
  }

  Future<DeployedContract> getContract() async {
    String abiFile = await rootBundle.loadString("assets/contract.json");
    String contractAddress = "0xa723Dc722D113aCF063a69b05dBFa1180F7A9Bf9";

    final contract = DeployedContract(ContractAbi.fromJson(abiFile, "Voting"),
        EthereumAddress.fromHex(contractAddress));

    return contract;
  }

  Future<List<dynamic>> callFunction(String name) async {
    final contract = await getContract();
    final function = contract.function(name);
    final result = await ethClient
        .call(contract: contract, function: function, params: []);
    return result;
  }

  Future<void> getTotalVotes() async {
    List<dynamic> resultsA = await callFunction("getTotalVotesAlpha");
    List<dynamic> resultsB = await callFunction("getTotalVotesBeta");
    totalVotesA = resultsA[0];
    totalVotesB = resultsB[0];

    setState(() {});
  }

  snackBar({String? label}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label!),
          CircularProgressIndicator(
            color: Colors.white,
          )
        ],
      ),
      duration: Duration(days: 1),
      backgroundColor: Colors.blue,
    ));
  }

  Future<void> vote(bool voteAlpha) async {
    snackBar(label: "Recording Vote");
    Credentials key =
        EthPrivateKey.fromHex("privateKeyCensoredForObviousReasons");
    final contract = await getContract();

    final function = contract.function(voteAlpha ? "voteAlpha" : "voteBeta");

    await ethClient.sendTransaction(
        key,
        Transaction.callContract(
            contract: contract, function: function, parameters: []),
        chainId: 4);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    snackBar(label: "verifying Vote");
    Future.delayed(const Duration(seconds: 20), () {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      snackBar(label: "retrieving votes");
      getTotalVotes();

      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(30),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          child: Text("A"),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Total Votes: ${totalVotesA ?? ""}",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    Column(
                      children: [
                        CircleAvatar(
                          child: Text("B"),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text("Total Votes: ${totalVotesB ?? ""}",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      vote(true);
                    },
                    child: Text('Vote Alpha'),
                    style: ElevatedButton.styleFrom(shape: StadiumBorder()),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      vote(false);
                    },
                    child: Text('Vote Beta'),
                    style: ElevatedButton.styleFrom(shape: StadiumBorder()),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
