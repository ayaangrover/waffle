import Link from 'next/link'
import { Button } from '@/components/ui/button'
import Image from 'next/image'

export function Nav() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-md shadow-md">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between py-4">
          <Link href="/" className="flex items-center">
          <Image
              src="./logo.png"
              alt="Waffle App Screenshot"
              width={120}
              height={120}
              className="object-cover w-full h-full"
            />
          </Link>
          <div className="space-x-4">
            <Link href="/" className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">Home</Link>
            <Link href="/features" className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">Features</Link>
            <Link href="/about" className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">About</Link>
            <Link href="https://akg.mintlify.app" target="_blank" className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">Docs</Link>
            <Button asChild variant="outline">
              <Link href="https://testflight.apple.com/join/XWN8vytA" target="_blank">Download</Link>
            </Button>
          </div>
        </div>
      </div>
    </nav>
  )
}