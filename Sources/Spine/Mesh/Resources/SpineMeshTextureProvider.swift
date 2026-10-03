import SpriteKit
#if os(iOS) || os(macOS)
import ImageIO
import Accelerate
#endif

public protocol SpineMeshTextureProvider {
    func region(named path: String) throws -> SpineMeshTextureRegion
}

public struct SpineMeshTextureRegion {
    public let texture: SKTexture
    public let pixelSize: CGSize
    public let originalSize: CGSize
    public let trimRect: CGRect
    public let uvTransform: CGAffineTransform

    public init(texture: SKTexture, pixelSize: CGSize, originalSize: CGSize,
                trimRect: CGRect, uvTransform: CGAffineTransform) throws {
        let t=uvTransform
        let numbers=[pixelSize.width,pixelSize.height,originalSize.width,originalSize.height,
                     trimRect.origin.x,trimRect.origin.y,trimRect.width,trimRect.height,t.a,t.b,t.c,t.d,t.tx,t.ty]
        let validPixels=[pixelSize.width,pixelSize.height,originalSize.width,originalSize.height].allSatisfy { $0>0 && $0.rounded()==$0 }
        guard numbers.allSatisfy(\.isFinite),validPixels,trimRect.width>0,trimRect.height>0,
              trimRect.minX>=0,trimRect.minY>=0,trimRect.maxX<=originalSize.width,trimRect.maxY<=originalSize.height,
              texture.textureRect()==CGRect(x:0,y:0,width:1,height:1),texture.size()==pixelSize else {
            throw SpineRuntimeError(.invalidTextureRegion,path:"/textures",message:"A region requires a canonical full texture, finite metadata, integral positive pixel sizes and a trim rectangle inside the original image.")
        }
        self.texture=texture;self.pixelSize=pixelSize;self.originalSize=originalSize
        self.trimRect=trimRect;self.uvTransform=uvTransform
    }
}

public final class SpineAtlasTextureProvider: SpineMeshTextureProvider {
    private var regions:[String:SpineMeshTextureRegion]=[:]

    public init(atlasText:String,pageData:[String:Data]) throws {
        #if os(iOS) || os(macOS)
        struct Region { let name:String;var fields:[String:String]=[:] }
        struct Page { let name:String;var fields:[String:String]=[:];var regions:[Region]=[] }
        var pages:[Page]=[],pageIndex:Int?,regionIndex:Int?
        for raw in atlasText.components(separatedBy:.newlines) {
            let line=raw.trimmingCharacters(in:.whitespaces)
            if line.isEmpty {pageIndex=nil;regionIndex=nil;continue}
            if let separator=line.firstIndex(of:":") {
                guard let page=pageIndex else {throw Self.invalid("atlas","Property before page name.")}
                let key=String(line[..<separator]).trimmingCharacters(in:.whitespaces)
                let value=String(line[line.index(after:separator)...]).trimmingCharacters(in:.whitespaces)
                if let region=regionIndex {pages[page].regions[region].fields[key]=value}
                else {pages[page].fields[key]=value}
            } else if let page=pageIndex {
                pages[page].regions.append(Region(name:line));regionIndex=pages[page].regions.count-1
            } else {pages.append(Page(name:line));pageIndex=pages.count-1;regionIndex=nil}
        }
        guard !pages.isEmpty else {throw Self.invalid("atlas","Atlas has no pages.")}
        for page in pages {
            guard let png=pageData[page.name] else {throw SpineRuntimeError(.missingTexture,path:Self.path(page.name),message:"Atlas page is missing.")}
            let pma=page.fields["pma"] ?? "false"
            guard pma=="true" || pma=="false" else {throw Self.invalid(page.name,"Invalid page pma flag.")}
            let image=try Self.decodePNG(png,premultiplied:pma=="true",name:page.name)
            let pageSize=CGSize(width:image.width,height:image.height)
            if let raw=page.fields["size"] {
                let size=try Self.numbers(raw,count:2,name:page.name)
                guard size==[CGFloat(image.width),CGFloat(image.height)] else {throw Self.invalid(page.name,"Declared page size does not match PNG pixels.")}
            }
            let texture=SKTexture(cgImage:image)
            texture.filteringMode=page.fields["filter"]?.components(separatedBy:",").first?.trimmingCharacters(in:.whitespaces)=="Nearest" || page.fields["filter"]==nil ? .nearest:.linear
            for region in page.regions {
                guard regions[region.name]==nil else {throw Self.invalid(region.name,"Duplicate atlas region name.")}
                let fields=region.fields
                let bounds:[CGFloat]
                if let raw=fields["bounds"] {bounds=try Self.numbers(raw,count:4,name:region.name)}
                else {bounds=try Self.numbers(fields["xy"] ?? "0,0",count:2,name:region.name)+Self.numbers(fields["size"] ?? "0,0",count:2,name:region.name)}
                let rotation=fields["rotate"] ?? "0"
                guard ["0","false","90","true"].contains(rotation) else {throw Self.invalid(region.name,"Only atlas rotations 0 and 90 are supported.")}
                let rotated=rotation=="90" || rotation=="true"
                let x=bounds[0],y=bounds[1],width=bounds[2],height=bounds[3]
                let offsets:[CGFloat]
                if let raw=fields["offsets"] {offsets=try Self.numbers(raw,count:4,name:region.name)}
                else {
                    let origin=try Self.numbers(fields["offset"] ?? "0,0",count:2,name:region.name)
                    let original=try fields["orig"].map {try Self.numbers($0,count:2,name:region.name)} ?? [width,height]
                    offsets=origin+original
                }
                guard bounds.allSatisfy({$0.rounded()==$0}),offsets.allSatisfy({$0.rounded()==$0}),x>=0,y>=0,width>0,height>0,
                      x+(rotated ? height:width)<=pageSize.width,y+(rotated ? width:height)<=pageSize.height else {
                    throw Self.invalid(region.name,"Packed region is outside its atlas page.")
                }
                let ox=offsets[0],oy=offsets[1],ow=offsets[2],oh=offsets[3]
                let transform:CGAffineTransform
                if rotated {
                    transform=CGAffineTransform(a:0,b:ow/pageSize.height,c:-oh/pageSize.width,d:0,
                        tx:(x+height+oy)/pageSize.width,ty:(pageSize.height-y-width-ox)/pageSize.height)
                } else {
                    transform=CGAffineTransform(a:ow/pageSize.width,b:0,c:0,d:oh/pageSize.height,
                        tx:(x-ox)/pageSize.width,ty:(pageSize.height-y-height-oy)/pageSize.height)
                }
                do {
                    regions[region.name]=try SpineMeshTextureRegion(texture:texture,pixelSize:pageSize,
                        originalSize:CGSize(width:ow,height:oh),trimRect:CGRect(x:ox,y:oy,width:width,height:height),uvTransform:transform)
                } catch {throw Self.invalid(region.name,"Invalid atlas region metadata: \(error.localizedDescription)")}
            }
        }
        #else
        throw SpineRuntimeError(.unsupportedPlatform,path:"/runtime/platform",message:"Mesh atlas loading is supported on macOS and iOS.")
        #endif
    }

    public func region(named path:String) throws -> SpineMeshTextureRegion {
        guard let region=regions[path] else {throw SpineRuntimeError(.missingTexture,path:Self.path(path),message:"Atlas region is missing.")}
        return region
    }

    private static func path(_ name:String)->String {"/textures/"+SpineRuntimeError.pointerComponent(name)}
    private static func invalid(_ name:String,_ message:String)->SpineRuntimeError {.init(.invalidTextureRegion,path:path(name),message:message)}
    private static func numbers(_ source:String,count:Int,name:String)throws->[CGFloat] {
        let parts=source.split(separator:",",omittingEmptySubsequences:false)
        guard parts.count==count else {throw invalid(name,"Invalid numeric atlas metadata component count.")}
        return try parts.map { part in
            guard let value=Double(part.trimmingCharacters(in:.whitespaces)),value.isFinite else {throw invalid(name,"Invalid numeric atlas metadata component.")}
            return CGFloat(value)
        }
    }

    #if os(iOS) || os(macOS)
    private static func decodePNG(_ data:Data,premultiplied:Bool,name:String)throws->CGImage {
        guard data.starts(with:[137,80,78,71,13,10,26,10]),let source=CGImageSourceCreateWithData(data as CFData,nil),
              let image=CGImageSourceCreateImageAtIndex(source,0,nil),image.width>0,image.height>0 else {
            throw invalid(name,"Atlas page is not a decodable PNG.")
        }
        // Request straight encoded RGBA, not a CGContext premultiply/unpremultiply round trip.
        // A Spine PMA PNG already stores premultiplied RGB despite PNG's straight-alpha tag.
        let colorSpace=CGColorSpaceCreateDeviceRGB()
        var format=vImage_CGImageFormat(bitsPerComponent:8,bitsPerPixel:32,colorSpace:Unmanaged.passUnretained(colorSpace),
            bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.last.rawValue|CGBitmapInfo.byteOrder32Big.rawValue),version:0,decode:nil,renderingIntent:.defaultIntent)
        var buffer=vImage_Buffer()
        guard vImageBuffer_InitWithCGImage(&buffer,&format,nil,image,vImage_Flags(kvImageNoFlags))==kvImageNoError else {
            throw invalid(name,"Unable to convert PNG components to RGBA.")
        }
        defer {free(buffer.data)}
        var pixels=Data(count:image.width*image.height*4)
        pixels.withUnsafeMutableBytes { destination in
            let bytes=destination.baseAddress!.assumingMemoryBound(to:UInt8.self)
            for y in 0..<image.height {
                let row=buffer.data.advanced(by:y*buffer.rowBytes).assumingMemoryBound(to:UInt8.self)
                for x in 0..<image.width {
                    let from=x*4,to=(y*image.width+x)*4,a=Int(row[from+3])
                    bytes[to+3]=UInt8(a)
                    for channel in 0..<3 {bytes[to+channel]=premultiplied ? row[from+channel]:UInt8((Int(row[from+channel])*a+127)/255)}
                }
            }
        }
        guard let provider=CGDataProvider(data:pixels as CFData),let result=CGImage(width:image.width,height:image.height,bitsPerComponent:8,bitsPerPixel:32,
            bytesPerRow:image.width*4,space:colorSpace,bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue),
            provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent) else {throw invalid(name,"Unable to materialize canonical page.")}
        return result
    }
    #endif
}
