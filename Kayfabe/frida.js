var addr = undefined;

function isAppModule(m) {
  return !/^\/(usr\/lib|System|Developer)\//.test(m.path) && /Kay/.test(m.path);
}

const appModules = new ModuleMap(isAppModule);
const appClasses = ObjC.enumerateLoadedClassesSync({ ownedBy: appModules });
console.log('appClasses:', JSON.stringify(appClasses));
for (var k in ObjC.classes) {
    if (k.includes("Kayfabe")) {
        console.log("K: ", k);
    }
}

var modules = Process.enumerateModules();
for (var mod of modules) {
    if (!mod.name.includes("Kayfabe")) {
        continue;
    }
    console.log(mod.name);//, mod.path);
    var symbols = mod.enumerateSymbols();
    for (var sym of symbols) {
        if (sym.name.includes("generatePlaintext")) {
            console.log(sym.type, sym.isGlobal, sym.section ? sym.section.id + " " + sym.section.protection : "", sym.name, sym.size, sym.address);
            if (sym.type == "section" && sym.section && sym.section.id == "0.__TEXT.__text") {
                addr = sym.address;
                console.log("Choosing address", addr);
            }
        }
    }
}

if (addr != undefined) {
    Interceptor.attach(new NativePointer(addr), {
        onEnter(args) {
            console.log("Entering!");
            console.log(ObjC.available);
            //console.log(args);
            //console.log(args[0]);
        },
        onLeave(retVal) {
            console.log("Returning!");
            console.log(retVal);
        }
    });
    /*
    Interceptor.replace(new NativePointer(addr), new {
        onEnter(args) {
            console.log("Entering!")
        }
    });
*/
}
