# porygon

The unofficial Pokémon Go Plus SDK. Implements the protocol for talking to 
[Nintendo's Bluetooth LE wristband](https://www.amazon.com/dp/B01H482N6E).

This project is under active development, and should allow you to create
scripted interactions with the wristband in other contexts soon. This will let 
you use the wristband in other apps than Pokémon Go (e.g. as a general Android 
notification device) and with other devices (e.g. laptops and smartwatches).

**NOTE**: This will obviously require you to buy the wristband.
The wristband hasn't been released yet, so development has been based on
examination of the Pokemon Go client. This is **not** a replacement for the
official Pokémon Go wristband, nor was it ever intended to be.
Go buy the thing wherever it's available for preorder; it's $35 and looks
like a pokéball.

Lua is a nice language for this in combination with native bindings to the
device's Bluetooth LE stack. This will allow cross-platform code reuse on
Android, iOS, and any other device with Bluetooth support.

Check the [wiki](https://github.com/numinit/porygon/wiki) for protocol notes.

## Contributing

If you have a contribution, submit it in a pull request. Please note that 
all contributions will be licensed under version 2 of the GNU General Public 
License.
