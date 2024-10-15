"use client"

import React, { useEffect } from 'react'
import { usePathname } from 'next/navigation'
import { motion, AnimatePresence } from 'framer-motion'

const pageVariants = {
  initial: { opacity: 0, y: 20 },
  in: { opacity: 1, y: 0 },
  out: { opacity: 0, y: -20 },
}

const pageTransition = {
  type: "tween",
  ease: [0.87, 0, 0.13, 1],
  duration: 0.5
}

const TabContent: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return (
    <AnimatePresence mode="wait">
      <motion.div
        initial="initial"
        animate="in"
        exit="out"
        variants={pageVariants}
        transition={pageTransition}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  )
}

const HomePage: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const pathname = usePathname()
  // const router = useRouter()
  // const [activeTab, setActiveTab] = useState(pathname)

  useEffect(() => {
    // setActiveTab(pathname)
  }, [pathname])

  // const handleTabChange = (tab: string) => {
    // router.push(tab)
  // }

  return (
    <div className="container mx-auto px-4">
      <TabContent>
        {children}
      </TabContent>
    </div>
  )
}

export default HomePage