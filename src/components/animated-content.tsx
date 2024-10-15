"use client"

import React, { useEffect, useState } from 'react'

interface AnimatedContentProps {
  children: React.ReactNode
}

const AnimatedContent: React.FC<AnimatedContentProps> = ({ children }) => {
  const [isVisible, setIsVisible] = useState(false)

  useEffect(() => {
    setIsVisible(true)
  }, [])

  return (
    <div
      className={`transition-all duration-800 ease-in-out-quart ${
        isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-5'
      }`}
    >
      {children}
    </div>
  )
}

export default AnimatedContent