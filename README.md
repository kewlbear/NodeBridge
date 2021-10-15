# NodeBridge

Swift package of a simple bridge between Node.js and Swift.

## Usage

```swift
import NodeBridge

Addon.handler = { env, value in
    print(Value(env: env, value: value).description)
}

Addon.ready = {
    Addon.callJS(dict: [
        "foo": "bar",
    ])
}
```

```javascript
const NativeBridge = process._linkedBinding('SwiftBridge');

NativeBridge.doSomethingUseful((msg, cb) => {
    console.log(msg);
    cb({baz: 'abc'});
});
```

For a real world example app, see https://github.com/kewlbear/Inssagram.

### Swift Package Manager

```
.package(url: "https://github.com/kewlbear/NodeBridge.git", .branch("main")),
```

## License

MIT
