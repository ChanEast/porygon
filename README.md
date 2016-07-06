# porygon

The unofficial Pokémon Go Plus SDK. Implements the protocol for talking to 
[Nintendo's Bluetooth LE wristband](https://www.amazon.com/dp/B01H482N6E).

This project is under active development, and should allow people to create
scripted interactions with the wristband in other contexts soon.

Check the [wiki](https://github.com/numinit/porygon/wiki) for protocol notes.

**NOTE**: This obviously requires the wristband to work. The wristband hasn't 
been released yet, so development has been based on examination of the Pokemon 
Go client.

Lua is a nice language for this in combination with native bindings to the
device's Bluetooth LE stack. This will allow cross-platform code reuse on
Android, iOS, and any other device with Bluetooth support.

## Contributing

If you have a contribution, please submit it in a pull request.
