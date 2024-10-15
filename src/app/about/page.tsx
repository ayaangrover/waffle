"use client"

import { useEffect } from 'react'

export default function About() {
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
      <div className="flex-1 container mx-auto px-4 py-24 md:py-32">
        <h1 className="text-4xl font-bold mb-12 text-center gradient-text animate-fade-down">About Waffle</h1>
        <div className="max-w-3xl mx-auto space-y-6 text-lg text-muted-foreground">
          <p className="animate-on-scroll">
            Waffle is a secure group chat application built with SwiftUI.
          </p>
          <p className="animate-on-scroll">
            The app prioritizes user privacy and security by implementing end-to-end encryption and leveraging Firebase&apos;s 
            secure protocols. Users can sign in using their Google accounts, ensuring a seamless and secure authentication process.
          </p>
          <p className="animate-on-scroll">
            As a developer, I&apos;m passionate about creating intuitive and secure communication tools. Waffle represents my 
            commitment to learning and applying new technologies in the service of user-friendly, privacy-focused applications.
          </p>
          <p className="animate-on-scroll">
            For more detailed information about Waffle's features and implementation, please check out our 
            <a href="https://akg.mintlify.app" target="_blank" rel="noopener noreferrer" className="text-primary hover:underline"> documentation</a>.
          </p>
        </div>
      </div>
    </div>
  )
}