GGWP_MINT_TO="0x57de268d237c952d9598180e90c751f1d5831358bf644d8750f455310961d86f::GGWP::mint_to"
ARGS="u64:100000000000000 address:0xf1a9e4828f80ac6c7c64590a450fca0763f30f5dac6883e2647ec52e55897bd6"

echo "aptos move run --function-id $GGWP_MINT_TO --args $ARGS"
aptos move run --function-id $GGWP_MINT_TO  --args $ARGS
