const NativeBridge = process._linkedBinding('SwiftBridge');

NativeBridge.doSomethingUseful((msg, cb) => {
    console.log(msg);
    cb({baz: 'abc'});
});
