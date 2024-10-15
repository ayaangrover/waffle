import './globals.css'
import type { Metadata } from 'next'
import { Montserrat } from 'next/font/google'
import { Nav } from '@/components/nav'
import dynamic from 'next/dynamic'
import HomePage from '@/components/home-page'

const montserrat = Montserrat({ 
  subsets: ['latin'],
  variable: '--font-montserrat',
})

const AnimatedBackground = dynamic(() => import('@/components/animated-background'), { ssr: false })

export const metadata: Metadata = {
  title: 'Waffle - Secure Group Chat App',
  description: 'End-to-end encrypted group chat app built with SwiftUI',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className={montserrat.variable}>
      <body className="font-sans">
        <AnimatedBackground />
        <Nav />
        <main className="min-h-screen bg-background/10 pt-16">
          <HomePage>{children}</HomePage>
        </main>
      </body>
    </html>
  )
}