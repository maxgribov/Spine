import argparse, pathlib, json
parser=argparse.ArgumentParser(description='Generate a temporary physical-iOS XCTest host for the unchanged library tests.')
parser.add_argument('--repo', required=True)
parser.add_argument('--output', required=True)
parser.add_argument('--team', required=True, help='Local development signing team; never stored in repository')
parser.add_argument('--bundle-id', default='dev.spine.skincomposition.tests')
args=parser.parse_args()
root=pathlib.Path(args.output).resolve(); root.mkdir(parents=True,exist_ok=True)
repo=pathlib.Path(args.repo).resolve(); team=args.team; hostid=args.bundle_id
(root/'Host.swift').write_text('import UIKit\n@main final class Host: UIResponder, UIApplicationDelegate { var window: UIWindow?\nfunc application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool { setenv("SPINE_MESH_ORACLE_OUTPUT", FileManager.default.temporaryDirectory.appendingPathComponent("spine-oracle").path, 1); UIApplication.shared.isIdleTimerDisabled = true; let w=UIWindow(frame: UIScreen.main.bounds); w.rootViewController=UIViewController(); w.makeKeyAndVisible(); window=w; return true } }\n')
(root/'BundleModule.swift').write_text('import Foundation\nprivate final class TestBundleToken {}\nextension Bundle { static let module = Bundle(for: TestBundleToken.self) }\n')
(root/'CompositionMemoryProbeTests.swift').write_text('import Foundation\nimport XCTest\nfinal class CompositionMemoryProbeTests: XCTestCase {\n    func testSharedCatalogMemory() throws { try record(distinct: false) }\n    func testDistinctCatalogMemory() throws { try record(distinct: true) }\n    private func record(distinct: Bool) throws {\n        let fixture = try XCTUnwrap(Bundle.module.resourceURL).appendingPathComponent("Mesh41/skin-composition/wardrobe.json")\n        let report = try runMemoryProbe(distinct: distinct, fixtureURL: fixture)\n        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])\n        let name = distinct ? "memory-distinct.json" : "memory-shared.json"\n        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")\n        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)\n        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]\n        try data.write(to: documents.appendingPathComponent(name))\n    }\n}\n')
objects={};counter=0
def obj(**value):
 global counter
 counter+=1;key=f'{counter:024X}';objects[key]=value;return key
def ref(path,kind='sourcecode.swift'):
 return obj(isa='PBXFileReference',lastKnownFileType=kind,path=str(path),sourceTree='<absolute>')
def phase(isa,refs): return obj(isa=isa,buildActionMask=2147483647,files=[obj(isa='PBXBuildFile',fileRef=x) for x in refs],runOnlyForDeploymentPostprocessing=0)
def configs(settings):
 return obj(isa='XCConfigurationList',buildConfigurations=[obj(isa='XCBuildConfiguration',buildSettings=settings,name='Debug')],defaultConfigurationIsVisible=0,defaultConfigurationName='Debug')
libfiles=[ref(x) for x in sorted((repo/'Sources/Spine').rglob('*.swift'))]
testfiles=[ref(x) for x in sorted((repo/'Tests/SpineTests').rglob('*.swift'))]+[ref(root/'BundleModule.swift'),ref(root/'CompositionMemoryProbeTests.swift'),ref(repo/'Examples/SkinComposition/Diagnostics/MemoryProbe.swift'),ref(repo/'Examples/SkinComposition/ScaledCatalog.swift')]
hostfile=ref(root/'Host.swift')
resource=repo/'Tests/SpineTests/Resources';resources=[ref(p,'text.json') for p in sorted(resource.glob('*.json'))]+[ref(p,'text.json') for p in sorted((resource/'Compatibility').glob('*.json'))]+[ref(resource/'Mesh41','folder')]
products=[]
def product(name,kind):
 x=obj(isa='PBXFileReference',explicitFileType=kind,path=name,sourceTree='BUILT_PRODUCTS_DIR');products.append(x);return x
libproduct=product('libSpine.a','archive.ar');hostproduct=product('SkinTestHost.app','wrapper.application');testproduct=product('SpineTests.xctest','wrapper.cfbundle')
base={'SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'13.0','SWIFT_VERSION':'5.0','SWIFT_OPTIMIZATION_LEVEL':'-Onone','ENABLE_TESTABILITY':'YES','DEBUG_INFORMATION_FORMAT':'dwarf','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG','CLANG_ENABLE_MODULES':'YES','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator'}
sign={'DEVELOPMENT_TEAM':team,'CODE_SIGN_STYLE':'Automatic','CODE_SIGN_IDENTITY':'Apple Development'}
lib=obj(isa='PBXNativeTarget',name='Spine',productName='Spine',productType='com.apple.product-type.library.static',productReference=libproduct,buildConfigurationList=configs(dict(base,PRODUCT_NAME='Spine',DEFINES_MODULE='YES',CODE_SIGNING_ALLOWED='NO',SKIP_INSTALL='YES')),buildPhases=[phase('PBXSourcesBuildPhase',libfiles)],buildRules=[],dependencies=[])
host=obj(isa='PBXNativeTarget',name='SkinTestHost',productName='SkinTestHost',productType='com.apple.product-type.application',productReference=hostproduct,buildConfigurationList=configs(dict(base,**sign,PRODUCT_NAME='SkinTestHost',PRODUCT_BUNDLE_IDENTIFIER=hostid,GENERATE_INFOPLIST_FILE='YES',INFOPLIST_KEY_UILaunchScreen_Generation='YES',TARGETED_DEVICE_FAMILY='1,2')),buildPhases=[phase('PBXSourcesBuildPhase',[hostfile])],buildRules=[],dependencies=[])
tests=obj(isa='PBXNativeTarget',name='SpineTests',productName='SpineTests',productType='com.apple.product-type.bundle.unit-test',productReference=testproduct,buildConfigurationList=configs(dict(base,**sign,PRODUCT_NAME='SpineTests',PRODUCT_BUNDLE_IDENTIFIER=hostid+'.xctest',GENERATE_INFOPLIST_FILE='YES',TEST_HOST='$(BUILT_PRODUCTS_DIR)/SkinTestHost.app/SkinTestHost',BUNDLE_LOADER='$(TEST_HOST)',LD_RUNPATH_SEARCH_PATHS='$(inherited) @executable_path/Frameworks @loader_path/Frameworks')),buildPhases=[phase('PBXSourcesBuildPhase',testfiles),phase('PBXResourcesBuildPhase',resources),phase('PBXFrameworksBuildPhase',[libproduct])],buildRules=[],dependencies=[obj(isa='PBXTargetDependency',target=lib),obj(isa='PBXTargetDependency',target=host)])
group=obj(isa='PBXGroup',children=libfiles+testfiles+[hostfile]+resources+[obj(isa='PBXGroup',name='Products',children=products,sourceTree='<group>')],sourceTree='<group>')
project=obj(isa='PBXProject',attributes={'LastUpgradeCheck':'1600','TargetAttributes':{tests:{'TestTargetID':host}}},buildConfigurationList=configs(base),compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','Base'],mainGroup=group,projectDirPath='',projectRoot='',targets=[lib,host,tests])
def fmt(x):
 if isinstance(x,dict):return '{'+''.join(json.dumps(str(k))+' = '+fmt(v)+';' for k,v in x.items())+'}'
 if isinstance(x,list):return '('+','.join(fmt(y) for y in x)+')'
 return json.dumps(str(x))
p=root/'SkinTests.xcodeproj';p.mkdir(exist_ok=True);(p/'project.pbxproj').write_text('// !$*UTF8*$!\n'+fmt({'archiveVersion':1,'classes':{},'objectVersion':56,'objects':objects,'rootObject':project}))
s=p/'xcshareddata/xcschemes';s.mkdir(parents=True,exist_ok=True)
br=f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{tests}" BuildableName="SpineTests.xctest" BlueprintName="SpineTests" ReferencedContainer="container:SkinTests.xcodeproj"/>'
(s/'SpineTests.xcscheme').write_text(f'<?xml version="1.0"?><Scheme LastUpgradeVersion="1600" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="YES">{br}</BuildActionEntry></BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{br}</TestableReference></Testables></TestAction></Scheme>')
print('Prepared targets:',len(libfiles),'library sources,',len(testfiles),'test/helper sources; app bundle:',hostid)
