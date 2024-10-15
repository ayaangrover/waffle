"use client"

import { Button } from '@/components/ui/button'
import Link from 'next/link'
import { useEffect } from 'react'

export default function Home() {
  useEffect(() => {
    const observerOptions = {
      root: null,
      rootMargin: '0px',
      threshold: 0.1
    }

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible')
        }
      })
    }, observerOptions)

    const animatedElements = document.querySelectorAll('.animate-on-scroll')
    animatedElements.forEach(el => observer.observe(el))

    return () => {
      animatedElements.forEach(el => observer.unobserve(el))
    }
  }, [])

  return (
    <div className="flex flex-col min-h-screen">
      <div className="flex-1 container mx-auto px-4 py-8 md:py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
          <div className="animate-fade-right">
            <h1 className="text-5xl font-bold mb-6 leading-tight gradient-text">Secure group chat, simplified</h1>
            <p className="text-xl mb-8 text-muted-foreground">
              End-to-end encrypted messaging for teams, built with SwiftUI.
            </p>
            <div className="space-x-4">
              <Button asChild size="lg" className="transition-colors hover:bg-primary hover:text-primary-foreground">
                <Link href="https://testflight.apple.com/join/XWN8vytA" target="_blank">Download Now</Link>
              </Button>
              <Button asChild variant="outline" size="lg" className="transition-colors hover:bg-secondary hover:text-secondary-foreground">
                <Link href="/features">Learn More</Link>
              </Button>
            </div>
          </div>
          <div className="relative h-[600px] rounded-lg overflow-hidden shadow-2xl animate-fade-left">
            <img
              src="./cover.png"
              alt="Waffle App Screenshot"
              className="object-cover w-full h-full"
            />
          </div>
        </div>
      </div>
      <div className="container mx-auto px-4 py-16">
        <h2 className="text-3xl font-bold mb-8 text-center gradient-text">Why Choose Waffle?</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {[
            { title: "End-to-End Encryption", description: "Your messages are secure and private." },
            { title: "Intuitive Design", description: "Built with SwiftUI for a seamless experience." },
            { title: "Cross-Platform", description: "Available on iOS and MacOS, with iPadOS, WatchOS, and an online site coming soon." }
          ].map((feature, index) => (
            <div key={index} className="bg-card p-6 rounded-lg shadow-md animate-on-scroll transition-all duration-300 hover:shadow-lg hover:-translate-y-2">
              <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
              <p className="text-muted-foreground">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
      <footer className="border-t py-6 text-center text-sm text-muted-foreground">
        <Link href="https://stats.uptimerobot.com/lSKnswJSGz" target="_blank" className="hover:text-foreground transition-colors">
          Server Status
        </Link>
      </footer>
    </div>
  )
}