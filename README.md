# WALLET PAY - POC CONTRATO PARA MICROPAGAMENTOS

Os contratos Solidity para a "Pay Wallet" é uma prova de conceito simples para micropagamentos.

Ele permite que os usuários depositem fundos, realizem micropagamentos e retirem seus saldos.

O contrato inclui funções para depositar, realizar micropagamentos e retirar fundos, juntamente com eventos para registrar atividades na blockchain. A segurança é enfatizada, incorporando verificações de estado, modos de visibilidade adequados. 



## Secure Ether Transfer
<https://fravoll.github.io/solidity-patterns/secure_ether_transfer.html>

ENDEREÇO PARA OS TESTES MUMBAI = 0x671Fe6fFC5b6552364Ed4576D8C807Aba578Ad5D

# TODO

- Transfer helper openzepellin
- Code trasaction submit
- EIP 3074 - <https://blog.mycrypto.com/eip-3074>
- Examples 3074 - <https://gist.github.com/adietrichs/ab69fa2e505341e3744114eda98a05ab>
- Secure Ether Transfer - <https://fravoll.github.io/solidity-patterns/secure_ether_transfer.html>

# Regras

O owner assina o codigo assinado  com a conta que assina o cartão.

# hardhat

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
npx hardhat coverage
```
