"use client"

import { Shield, Lock, MessageCircle, Zap, Users, Globe } from 'lucide-react'
import { useEffect } from 'react'

export default function Features() {
  const features = [
    {
      title: 'End-to-End Encryption',
      description: 'Your messages are secure and private, visible only to you and your intended rooms.',
      icon: Lock,
    },
    {
      title: 'Firebase Security',
      description: 'We use Firebase\'s secure protocols to ensure your data is safe and protected.',
      icon: Shield,
    },
    {
      title: 'Group Chat',
      description: 'Create and manage group chats with ease, perfect for teams, friends, and family.',
      icon: MessageCircle,
    },
    {
      title: 'Lightning Fast',
      description: 'Optimized for speed, Waffle ensures your messages are delivered instantly.',
      icon: Zap,
    },
    {
      title: 'User-Friendly',
      description: 'Intuitive interface designed for seamless communication across all devices.',
      icon: Users,
    },
    {
      title: 'Cross-Platform',
      description: 'Available on iOS and MacOS, with iPadOS, WatchOS, and an online site coming soon.',
      icon: Globe,
    },
  ]

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
        <h1 className="text-4xl font-bold mb-12 text-center gradient-text animate-fade-down">Features</h1>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <div key={index} className="bg-card p-6 rounded-lg shadow-md transition-all duration-300 hover:shadow-lg hover:-translate-y-2 animate-on-scroll">
              <feature.icon className="w-12 h-12 mb-4 text-primary animate-float" />
              <h2 className="text-2xl font-semibold mb-2">{feature.title}</h2>
              <p className="text-muted-foreground">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}