import type { Project } from '../components/projects/ProjectCard';

export const placeholderProjects: Project[] = [
  {
    id: '1',
  thumbnailUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=400&q=80', // Film: movie background
    title: 'Echoes of the Void',
    creator: 'Jane Doe',
    type: 'Film',
    description: 'A sci-fi film exploring the mysteries of deep space and human connection.',
    fundingCurrent: 75000,
    fundingGoal: 100000,
    daysLeft: 15
  },
  {
    id: '2',
  thumbnailUrl: 'https://images.unsplash.com/photo-1515378791036-0648a3ef77b2?auto=format&fit=crop&w=400&q=80', // Music: music background
    title: 'Cyber Sunset',
    creator: 'John Smith',
    type: 'Music',
    description: 'A synthwave album inspired by retro-futurism and city nights.',
    fundingCurrent: 45000,
    fundingGoal: 50000,
    daysLeft: 30
  },
  {
    id: '3',
  thumbnailUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80', // Art: artist background
    title: 'The Last Artisan',
    creator: 'Emily White',
    type: 'Art',
    description: 'A documentary and gallery show about traditional crafts in the modern world.',
    fundingCurrent: 120000,
    fundingGoal: 200000,
    daysLeft: 45
  },
  {
    id: '4',
  thumbnailUrl: 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80', // Comedy: comedy background
    title: 'Forgotten Melodies',
    creator: 'Michael Brown',
    type: 'Podcast',
    description: 'A podcast series reviving lost music and the stories behind them.',
    fundingCurrent: 25000,
    fundingGoal: 60000,
    daysLeft: 20
  },
  {
    id: '5',
  thumbnailUrl: 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80', // Film: movie background (repeat or replace as needed)
    title: 'Beneath the Surface',
    creator: 'Sarah Green',
    type: 'Animation',
    description: 'An animated short about ocean life and environmental change.',
    fundingCurrent: 95000,
    fundingGoal: 100000,
    daysLeft: 5
  },
  {
    id: '6',
  thumbnailUrl: 'https://images.unsplash.com/photo-1465101178521-c1a9136a3b99?auto=format&fit=crop&w=400&q=80', // Comedy: comedy background (repeat or replace as needed)
    title: 'City of Glass',
    creator: 'David Black',
    type: 'Comedy',
    description: 'A stand-up comedy special about life in a futuristic city.',
    fundingCurrent: 30000,
    fundingGoal: 150000,
    daysLeft: 60
  },
];
