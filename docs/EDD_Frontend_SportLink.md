# SportLink - Frontend Engineering Design Document (EDD)

## 1. System Overview

### 1.1 Purpose
This document outlines the frontend architecture, component design, state management, and technical implementation details for the SportLink web application.

### 1.2 Scope
- React-based web application architecture
- Component library and design system
- State management and data flow
- Routing and navigation structure
- Authentication and authorization flows
- Performance optimization strategies
- Mobile responsiveness and accessibility
- Build and deployment processes

### 1.3 System Context
The frontend serves as the primary user interface for the SportLink platform, providing an intuitive and responsive web experience that connects to the backend APIs for data and functionality.

## 2. Technology Stack

### 2.1 Core Technologies
- **Framework**: React 18+ with TypeScript
- **Build Tool**: Vite (for fast development and building)
- **Styling**: Tailwind CSS + CSS Modules
- **State Management**: Zustand (lightweight alternative to Redux)
- **Routing**: React Router v6
- **HTTP Client**: Axios with interceptors
- **Form Handling**: React Hook Form + Zod validation

### 2.2 UI/UX Libraries
- **Component Library**: Radix UI (unstyled, accessible components)
- **Icons**: Lucide React (consistent icon set)
- **Animations**: Framer Motion
- **Date Handling**: date-fns
- **File Upload**: React Dropzone
- **Image Optimization**: React Image Gallery

### 2.3 Development Tools
- **Package Manager**: npm
- **Code Quality**: ESLint + Prettier
- **Testing**: Vitest + React Testing Library
- **Type Checking**: TypeScript 5+
- **Git Hooks**: Husky + lint-staged
- **Storybook**: Component documentation and testing

### 2.4 Performance & Monitoring
- **Bundle Analyzer**: webpack-bundle-analyzer
- **Error Tracking**: Sentry (future integration)
- **Analytics**: Google Analytics 4 (future integration)
- **PWA**: Service Worker for offline capabilities (future)

## 3. Application Architecture

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Browser Environment                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │    React    │  │   Router    │  │  Service    │        │
│  │ Components  │  │   (Pages)   │  │   Worker    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Zustand   │  │    Axios    │  │   Utility   │        │
│  │   Store     │  │   Client    │  │  Functions  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│                     Backend APIs                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │    Auth     │  │    Core     │  │    Media    │        │
│  │   Service   │  │     API     │  │   Service   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Folder Structure

```
src/
├── components/          # Reusable UI components
│   ├── ui/             # Basic UI components (Button, Input, etc.)
│   ├── forms/          # Form components
│   ├── layout/         # Layout components (Header, Sidebar, etc.)
│   └── feature/        # Feature-specific components
├── pages/              # Page components (route components)
├── hooks/              # Custom React hooks
├── stores/             # Zustand stores
├── services/           # API services and utilities
├── types/              # TypeScript type definitions
├── utils/              # Utility functions
├── assets/             # Static assets (images, icons, etc.)
├── styles/             # Global styles and Tailwind config
└── __tests__/          # Test files
```

### 3.3 Component Architecture

```
Application
├── Layout
│   ├── Header
│   │   ├── Navigation
│   │   ├── SearchBar
│   │   ├── NotificationIcon
│   │   └── UserMenu
│   ├── Sidebar (conditionally rendered)
│   └── Footer
├── Pages
│   ├── Auth Pages
│   ├── Profile Pages
│   ├── Feed Pages
│   ├── Search Pages
│   ├── Events Pages
│   └── Messages Pages
└── Global Components
    ├── Modals
    ├── Toast Notifications
    └── Loading States
```

## 4. Component Design System

### 4.1 Design Tokens

```typescript
// Design tokens configuration
export const designTokens = {
  colors: {
    primary: {
      50: '#f0f9ff',
      500: '#3b82f6',
      600: '#2563eb',
      700: '#1d4ed8',
      900: '#1e3a8a'
    },
    secondary: {
      50: '#f8fafc',
      500: '#64748b',
      600: '#475569',
      700: '#334155',
      900: '#0f172a'
    },
    success: '#22c55e',
    warning: '#f59e0b',
    error: '#ef4444',
    info: '#3b82f6'
  },
  
  spacing: {
    xs: '0.5rem',   // 8px
    sm: '0.75rem',  // 12px
    md: '1rem',     // 16px
    lg: '1.5rem',   // 24px
    xl: '2rem',     // 32px
    '2xl': '3rem'   // 48px
  },
  
  typography: {
    fontFamily: {
      sans: ['Inter', 'system-ui', 'sans-serif'],
      mono: ['JetBrains Mono', 'monospace']
    },
    fontSize: {
      xs: '0.75rem',
      sm: '0.875rem',
      base: '1rem',
      lg: '1.125rem',
      xl: '1.25rem',
      '2xl': '1.5rem',
      '3xl': '1.875rem'
    }
  },
  
  borderRadius: {
    none: '0',
    sm: '0.25rem',
    md: '0.375rem',
    lg: '0.5rem',
    xl: '0.75rem',
    full: '9999px'
  }
};
```

### 4.2 Base UI Components

#### 4.2.1 Button Component
```typescript
// components/ui/Button.tsx
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'md',
  isLoading = false,
  leftIcon,
  rightIcon,
  children,
  className,
  disabled,
  ...props
}) => {
  const baseStyles = 'inline-flex items-center justify-center font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none';
  
  const variants = {
    primary: 'bg-primary-600 hover:bg-primary-700 text-white focus:ring-primary-500',
    secondary: 'bg-secondary-100 hover:bg-secondary-200 text-secondary-900 focus:ring-secondary-500',
    outline: 'border border-gray-300 bg-white hover:bg-gray-50 text-gray-700 focus:ring-primary-500',
    ghost: 'hover:bg-gray-100 text-gray-700 focus:ring-primary-500',
    danger: 'bg-red-600 hover:bg-red-700 text-white focus:ring-red-500'
  };
  
  const sizes = {
    sm: 'px-3 py-1.5 text-sm rounded-md',
    md: 'px-4 py-2 text-sm rounded-md',
    lg: 'px-6 py-3 text-base rounded-lg'
  };
  
  return (
    <button
      className={cn(
        baseStyles,
        variants[variant],
        sizes[size],
        className
      )}
      disabled={disabled || isLoading}
      {...props}
    >
      {isLoading && <Spinner className="mr-2 h-4 w-4" />}
      {!isLoading && leftIcon && <span className="mr-2">{leftIcon}</span>}
      {children}
      {!isLoading && rightIcon && <span className="ml-2">{rightIcon}</span>}
    </button>
  );
};
```

#### 4.2.2 Input Component
```typescript
// components/ui/Input.tsx
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helper?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const Input: React.FC<InputProps> = ({
  label,
  error,
  helper,
  leftIcon,
  rightIcon,
  className,
  id,
  ...props
}) => {
  const inputId = id || `input-${Math.random().toString(36).substr(2, 9)}`;
  
  return (
    <div className="w-full">
      {label && (
        <label htmlFor={inputId} className="block text-sm font-medium text-gray-700 mb-1">
          {label}
        </label>
      )}
      
      <div className="relative">
        {leftIcon && (
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <span className="text-gray-400 text-sm">{leftIcon}</span>
          </div>
        )}
        
        <input
          id={inputId}
          className={cn(
            'block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-primary-500 focus:border-primary-500',
            leftIcon && 'pl-10',
            rightIcon && 'pr-10',
            error && 'border-red-300 focus:ring-red-500 focus:border-red-500',
            className
          )}
          {...props}
        />
        
        {rightIcon && (
          <div className="absolute inset-y-0 right-0 pr-3 flex items-center">
            <span className="text-gray-400 text-sm">{rightIcon}</span>
          </div>
        )}
      </div>
      
      {error && (
        <p className="mt-1 text-sm text-red-600">{error}</p>
      )}
      
      {helper && !error && (
        <p className="mt-1 text-sm text-gray-500">{helper}</p>
      )}
    </div>
  );
};
```

### 4.3 Layout Components

#### 4.3.1 Header Component
```typescript
// components/layout/Header.tsx
export const Header: React.FC = () => {
  const { user, logout } = useAuthStore();
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  
  return (
    <header className="bg-white shadow-sm border-b border-gray-200 sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <div className="flex items-center">
            <Link to="/" className="flex items-center">
              <img src="/logo.svg" alt="SportLink" className="h-8 w-auto" />
              <span className="ml-2 text-xl font-bold text-primary-600">SportLink</span>
            </Link>
          </div>
          
          {/* Search Bar */}
          <div className="flex-1 max-w-lg mx-8">
            <SearchBar />
          </div>
          
          {/* Navigation & User Menu */}
          <div className="flex items-center space-x-4">
            <Navigation />
            <NotificationButton />
            <UserMenu />
          </div>
        </div>
      </div>
    </header>
  );
};
```

#### 4.3.2 Navigation Component
```typescript
// components/layout/Navigation.tsx
export const Navigation: React.FC = () => {
  const location = useLocation();
  
  const navItems = [
    { name: 'Feed', href: '/feed', icon: Home },
    { name: 'Discover', href: '/discover', icon: Search },
    { name: 'Events', href: '/events', icon: Calendar },
    { name: 'Messages', href: '/messages', icon: MessageCircle }
  ];
  
  return (
    <nav className="flex space-x-1">
      {navItems.map((item) => {
        const isActive = location.pathname.startsWith(item.href);
        
        return (
          <Link
            key={item.name}
            to={item.href}
            className={cn(
              'flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors',
              isActive
                ? 'bg-primary-100 text-primary-700'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
            )}
          >
            <item.icon className="h-4 w-4 mr-2" />
            <span className="hidden md:block">{item.name}</span>
          </Link>
        );
      })}
    </nav>
  );
};
```

## 5. State Management

### 5.1 Zustand Store Architecture

```typescript
// stores/authStore.ts
interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  userType: 'player' | 'coach' | 'club';
  profileImageUrl?: string;
  isVerified: boolean;
}

interface AuthState {
  user: User | null;
  accessToken: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

interface AuthActions {
  login: (credentials: LoginCredentials) => Promise<void>;
  register: (userData: RegisterData) => Promise<void>;
  logout: () => void;
  refreshToken: () => Promise<void>;
  clearError: () => void;
  updateUser: (userData: Partial<User>) => void;
}

export const useAuthStore = create<AuthState & AuthActions>((set, get) => ({
  // State
  user: null,
  accessToken: localStorage.getItem('accessToken'),
  isAuthenticated: !!localStorage.getItem('accessToken'),
  isLoading: false,
  error: null,
  
  // Actions
  login: async (credentials) => {
    set({ isLoading: true, error: null });
    
    try {
      const response = await authService.login(credentials);
      const { user, accessToken, refreshToken } = response.data;
      
      localStorage.setItem('accessToken', accessToken);
      localStorage.setItem('refreshToken', refreshToken);
      
      set({
        user,
        accessToken,
        isAuthenticated: true,
        isLoading: false
      });
    } catch (error) {
      set({
        error: error.message,
        isLoading: false
      });
    }
  },
  
  logout: () => {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    
    set({
      user: null,
      accessToken: null,
      isAuthenticated: false,
      error: null
    });
  },
  
  // ... other actions
}));
```

### 5.2 Additional Stores

```typescript
// stores/postsStore.ts
interface PostsState {
  posts: Post[];
  isLoading: boolean;
  hasMore: boolean;
  page: number;
  filters: {
    sportId?: string;
    userType?: string;
    location?: string;
  };
}

export const usePostsStore = create<PostsState & PostsActions>((set, get) => ({
  posts: [],
  isLoading: false,
  hasMore: true,
  page: 1,
  filters: {},
  
  fetchPosts: async (reset = false) => {
    const { page, filters, posts } = get();
    set({ isLoading: true });
    
    try {
      const response = await postsService.getFeed({
        page: reset ? 1 : page,
        ...filters
      });
      
      set({
        posts: reset ? response.data.posts : [...posts, ...response.data.posts],
        hasMore: response.data.pagination.hasNext,
        page: reset ? 2 : page + 1,
        isLoading: false
      });
    } catch (error) {
      set({ isLoading: false });
    }
  },
  
  // ... other actions
}));
```

## 6. Routing Structure

### 6.1 Route Configuration

```typescript
// routes/index.tsx
import { createBrowserRouter } from 'react-router-dom';
import { ProtectedRoute } from './ProtectedRoute';
import { AuthLayout } from '../components/layout/AuthLayout';
import { AppLayout } from '../components/layout/AppLayout';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <AppLayout />,
    children: [
      {
        index: true,
        element: <Navigate to="/feed" replace />
      },
      {
        path: 'feed',
        element: <ProtectedRoute><FeedPage /></ProtectedRoute>
      },
      {
        path: 'discover',
        element: <ProtectedRoute><DiscoverPage /></ProtectedRoute>
      },
      {
        path: 'profile',
        children: [
          {
            path: ':userId',
            element: <ProtectedRoute><ProfilePage /></ProtectedRoute>
          },
          {
            path: 'edit',
            element: <ProtectedRoute><EditProfilePage /></ProtectedRoute>
          }
        ]
      },
      {
        path: 'events',
        children: [
          {
            index: true,
            element: <ProtectedRoute><EventsPage /></ProtectedRoute>
          },
          {
            path: ':eventId',
            element: <ProtectedRoute><EventDetailPage /></ProtectedRoute>
          },
          {
            path: 'create',
            element: <ProtectedRoute><CreateEventPage /></ProtectedRoute>
          }
        ]
      },
      {
        path: 'messages',
        children: [
          {
            index: true,
            element: <ProtectedRoute><MessagesPage /></ProtectedRoute>
          },
          {
            path: ':conversationId',
            element: <ProtectedRoute><ConversationPage /></ProtectedRoute>
          }
        ]
      }
    ]
  },
  {
    path: '/auth',
    element: <AuthLayout />,
    children: [
      {
        path: 'login',
        element: <LoginPage />
      },
      {
        path: 'register',
        element: <RegisterPage />
      },
      {
        path: 'forgot-password',
        element: <ForgotPasswordPage />
      }
    ]
  },
  {
    path: '*',
    element: <NotFoundPage />
  }
]);
```

### 6.2 Protected Route Component

```typescript
// routes/ProtectedRoute.tsx
interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredUserType?: 'player' | 'coach' | 'club';
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({
  children,
  requiredUserType
}) => {
  const { isAuthenticated, user } = useAuthStore();
  const location = useLocation();
  
  if (!isAuthenticated) {
    return <Navigate to="/auth/login" state={{ from: location }} replace />;
  }
  
  if (requiredUserType && user?.userType !== requiredUserType) {
    return <Navigate to="/unauthorized" replace />;
  }
  
  return <>{children}</>;
};
```

## 7. API Integration

### 7.1 HTTP Client Configuration

```typescript
// services/api.ts
import axios, { AxiosResponse, AxiosError } from 'axios';
import { useAuthStore } from '../stores/authStore';

// Create axios instance
export const api = axios.create({
  baseURL: process.env.VITE_API_BASE_URL || 'http://localhost:3001/api/v1',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request interceptor for adding auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('accessToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for handling errors and token refresh
api.interceptors.response.use(
  (response: AxiosResponse) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as any;
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        const refreshToken = localStorage.getItem('refreshToken');
        if (refreshToken) {
          const response = await axios.post('/auth/refresh', {
            refreshToken
          });
          
          const { accessToken } = response.data;
          localStorage.setItem('accessToken', accessToken);
          
          // Retry original request
          originalRequest.headers.Authorization = `Bearer ${accessToken}`;
          return api(originalRequest);
        }
      } catch (refreshError) {
        // Refresh failed, redirect to login
        useAuthStore.getState().logout();
        window.location.href = '/auth/login';
      }
    }
    
    return Promise.reject(error);
  }
);
```

### 7.2 API Service Classes

```typescript
// services/authService.ts
export class AuthService {
  async login(credentials: LoginCredentials): Promise<ApiResponse<LoginResponse>> {
    const response = await api.post('/auth/login', credentials);
    return response.data;
  }
  
  async register(userData: RegisterData): Promise<ApiResponse<RegisterResponse>> {
    const response = await api.post('/auth/register', userData);
    return response.data;
  }
  
  async forgotPassword(email: string): Promise<ApiResponse<void>> {
    const response = await api.post('/auth/forgot-password', { email });
    return response.data;
  }
  
  async resetPassword(token: string, password: string): Promise<ApiResponse<void>> {
    const response = await api.post('/auth/reset-password', { token, password });
    return response.data;
  }
}

export const authService = new AuthService();
```

### 7.3 Custom Hooks for API Calls

```typescript
// hooks/useApi.ts
export function useApi<T>(
  apiCall: () => Promise<T>,
  dependencies: React.DependencyList = []
) {
  const [data, setData] = useState<T | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const execute = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    
    try {
      const result = await apiCall();
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setIsLoading(false);
    }
  }, dependencies);
  
  useEffect(() => {
    execute();
  }, [execute]);
  
  return { data, isLoading, error, refetch: execute };
}

// Usage example
export function useUserProfile(userId: string) {
  return useApi(
    () => userService.getProfile(userId),
    [userId]
  );
}
```

## 8. Form Handling

### 8.1 Form Component with Validation

```typescript
// components/forms/LoginForm.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const loginSchema = z.object({
  identifier: z.string().min(1, 'Email or phone is required'),
  password: z.string().min(8, 'Password must be at least 8 characters')
});

type LoginFormData = z.infer<typeof loginSchema>;

export const LoginForm: React.FC = () => {
  const { login, isLoading, error } = useAuthStore();
  
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting }
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema)
  });
  
  const onSubmit = async (data: LoginFormData) => {
    await login(data);
  };
  
  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <Input
        label="Email or Phone"
        type="text"
        placeholder="Enter your email or phone number"
        error={errors.identifier?.message}
        {...register('identifier')}
      />
      
      <Input
        label="Password"
        type="password"
        placeholder="Enter your password"
        error={errors.password?.message}
        {...register('password')}
      />
      
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-md p-3">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}
      
      <Button
        type="submit"
        variant="primary"
        size="lg"
        className="w-full"
        isLoading={isSubmitting || isLoading}
      >
        Sign In
      </Button>
    </form>
  );
};
```

### 8.2 Multi-step Form Component

```typescript
// components/forms/ProfileSetupForm.tsx
export const ProfileSetupForm: React.FC = () => {
  const [currentStep, setCurrentStep] = useState(1);
  const [formData, setFormData] = useState<Partial<ProfileData>>({});
  
  const steps = [
    { id: 1, title: 'Basic Information', component: BasicInfoStep },
    { id: 2, title: 'Sports & Skills', component: SportsStep },
    { id: 3, title: 'Profile Picture', component: ProfilePictureStep }
  ];
  
  const nextStep = () => setCurrentStep(prev => Math.min(prev + 1, steps.length));
  const prevStep = () => setCurrentStep(prev => Math.max(prev - 1, 1));
  
  const updateFormData = (stepData: Partial<ProfileData>) => {
    setFormData(prev => ({ ...prev, ...stepData }));
  };
  
  return (
    <div className="max-w-2xl mx-auto">
      {/* Progress Indicator */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          {steps.map((step, index) => (
            <div
              key={step.id}
              className={cn(
                'flex items-center',
                index < steps.length - 1 && 'flex-1'
              )}
            >
              <div
                className={cn(
                  'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
                  step.id <= currentStep
                    ? 'bg-primary-600 text-white'
                    : 'bg-gray-200 text-gray-600'
                )}
              >
                {step.id}
              </div>
              {index < steps.length - 1 && (
                <div
                  className={cn(
                    'flex-1 h-0.5 mx-4',
                    step.id < currentStep ? 'bg-primary-600' : 'bg-gray-200'
                  )}
                />
              )}
            </div>
          ))}
        </div>
      </div>
      
      {/* Current Step Component */}
      <div className="bg-white rounded-lg shadow p-6">
        {steps.map(step => (
          step.id === currentStep && (
            <step.component
              key={step.id}
              data={formData}
              onNext={nextStep}
              onPrev={prevStep}
              onUpdate={updateFormData}
              isFirst={currentStep === 1}
              isLast={currentStep === steps.length}
            />
          )
        ))}
      </div>
    </div>
  );
};
```

## 9. Real-time Features

### 9.1 WebSocket Integration

```typescript
// hooks/useWebSocket.ts
export function useWebSocket(url: string) {
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [lastMessage, setLastMessage] = useState<any>(null);
  
  useEffect(() => {
    const token = localStorage.getItem('accessToken');
    const wsUrl = `${url}?token=${token}`;
    
    const ws = new WebSocket(wsUrl);
    
    ws.onopen = () => {
      setIsConnected(true);
      setSocket(ws);
    };
    
    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      setLastMessage(message);
    };
    
    ws.onclose = () => {
      setIsConnected(false);
      setSocket(null);
    };
    
    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
    
    return () => {
      ws.close();
    };
  }, [url]);
  
  const sendMessage = useCallback((message: any) => {
    if (socket && isConnected) {
      socket.send(JSON.stringify(message));
    }
  }, [socket, isConnected]);
  
  return { isConnected, lastMessage, sendMessage };
}
```

### 9.2 Real-time Notifications

```typescript
// hooks/useNotifications.ts
export function useNotifications() {
  const { lastMessage } = useWebSocket(WS_ENDPOINTS.notifications);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  
  useEffect(() => {
    if (lastMessage?.type === 'notification') {
      setNotifications(prev => [lastMessage.data, ...prev]);
      
      // Show toast notification
      toast.info(lastMessage.data.message, {
        onClick: () => {
          // Handle notification click
          window.location.href = lastMessage.data.url;
        }
      });
    }
  }, [lastMessage]);
  
  const markAsRead = (notificationId: string) => {
    setNotifications(prev =>
      prev.map(notif =>
        notif.id === notificationId
          ? { ...notif, isRead: true }
          : notif
      )
    );
  };
  
  return { notifications, markAsRead };
}
```

## 10. Performance Optimization

### 10.1 Code Splitting & Lazy Loading

```typescript
// Lazy load pages
const FeedPage = lazy(() => import('../pages/FeedPage'));
const ProfilePage = lazy(() => import('../pages/ProfilePage'));
const MessagesPage = lazy(() => import('../pages/MessagesPage'));

// Lazy load components
const PostModal = lazy(() => import('../components/modals/PostModal'));
const VideoPlayer = lazy(() => import('../components/media/VideoPlayer'));

// With loading fallback
function LazyWrapper({ children }: { children: React.ReactNode }) {
  return (
    <Suspense fallback={<PageSkeleton />}>
      {children}
    </Suspense>
  );
}
```

### 10.2 Virtual Scrolling for Large Lists

```typescript
// components/VirtualizedFeed.tsx
import { FixedSizeList as List } from 'react-window';
import InfiniteLoader from 'react-window-infinite-loader';

interface VirtualizedFeedProps {
  posts: Post[];
  loadMore: () => void;
  hasMore: boolean;
}

export const VirtualizedFeed: React.FC<VirtualizedFeedProps> = ({
  posts,
  loadMore,
  hasMore
}) => {
  const itemCount = hasMore ? posts.length + 1 : posts.length;
  const isItemLoaded = (index: number) => !!posts[index];
  
  const Item = ({ index, style }: { index: number; style: React.CSSProperties }) => {
    const post = posts[index];
    
    return (
      <div style={style}>
        {post ? (
          <PostCard post={post} />
        ) : (
          <PostSkeleton />
        )}
      </div>
    );
  };
  
  return (
    <InfiniteLoader
      isItemLoaded={isItemLoaded}
      itemCount={itemCount}
      loadMoreItems={loadMore}
    >
      {({ onItemsRendered, ref }) => (
        <List
          ref={ref}
          height={800}
          itemCount={itemCount}
          itemSize={200}
          onItemsRendered={onItemsRendered}
        >
          {Item}
        </List>
      )}
    </InfiniteLoader>
  );
};
```

### 10.3 Image Optimization

```typescript
// components/OptimizedImage.tsx
interface OptimizedImageProps {
  src: string;
  alt: string;
  width?: number;
  height?: number;
  className?: string;
  priority?: boolean;
}

export const OptimizedImage: React.FC<OptimizedImageProps> = ({
  src,
  alt,
  width,
  height,
  className,
  priority = false
}) => {
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(false);
  
  // Generate different sizes for responsive images
  const generateSrcSet = (baseSrc: string) => {
    const sizes = [300, 600, 900, 1200];
    return sizes
      .map(size => `${baseSrc}?w=${size}&q=80 ${size}w`)
      .join(', ');
  };
  
  return (
    <div className={cn('relative overflow-hidden', className)}>
      {isLoading && (
        <div className="absolute inset-0 bg-gray-200 animate-pulse" />
      )}
      
      {error ? (
        <div className="flex items-center justify-center h-full bg-gray-100">
          <ImageIcon className="h-8 w-8 text-gray-400" />
        </div>
      ) : (
        <img
          src={src}
          srcSet={generateSrcSet(src)}
          sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
          alt={alt}
          width={width}
          height={height}
          loading={priority ? 'eager' : 'lazy'}
          className={cn(
            'transition-opacity duration-300',
            isLoading ? 'opacity-0' : 'opacity-100'
          )}
          onLoad={() => setIsLoading(false)}
          onError={() => {
            setIsLoading(false);
            setError(true);
          }}
        />
      )}
    </div>
  );
};
```

## 11. Accessibility & Mobile Responsiveness

### 11.1 Accessibility Implementation

```typescript
// hooks/useAccessibility.ts
export function useAccessibility() {
  const [announcements, setAnnouncements] = useState<string[]>([]);
  
  const announce = (message: string, priority: 'polite' | 'assertive' = 'polite') => {
    setAnnouncements(prev => [...prev, message]);
    
    // Auto-remove after announcement
    setTimeout(() => {
      setAnnouncements(prev => prev.slice(1));
    }, 1000);
  };
  
  return { announcements, announce };
}

// Screen reader announcements
export const LiveRegion: React.FC = () => {
  const { announcements } = useAccessibility();
  
  return (
    <div
      aria-live="polite"
      aria-atomic="true"
      className="sr-only"
    >
      {announcements.map((announcement, index) => (
        <span key={index}>{announcement}</span>
      ))}
    </div>
  );
};
```

### 11.2 Responsive Design Patterns

```typescript
// hooks/useResponsive.ts
export function useResponsive() {
  const [windowSize, setWindowSize] = useState({
    width: window.innerWidth,
    height: window.innerHeight
  });
  
  useEffect(() => {
    const handleResize = () => {
      setWindowSize({
        width: window.innerWidth,
        height: window.innerHeight
      });
    };
    
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);
  
  return {
    isMobile: windowSize.width < 768,
    isTablet: windowSize.width >= 768 && windowSize.width < 1024,
    isDesktop: windowSize.width >= 1024,
    windowSize
  };
}
```

### 11.3 Mobile-First Components

```typescript
// components/MobileNavigation.tsx
export const MobileNavigation: React.FC = () => {
  const { isMobile } = useResponsive();
  const [isOpen, setIsOpen] = useState(false);
  
  if (!isMobile) return null;
  
  return (
    <>
      {/* Mobile menu button */}
      <button
        onClick={() => setIsOpen(true)}
        className="md:hidden p-2 rounded-md text-gray-600 hover:bg-gray-100"
        aria-label="Open navigation menu"
      >
        <Menu className="h-6 w-6" />
      </button>
      
      {/* Mobile slide-out menu */}
      <AnimatePresence>
        {isOpen && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black bg-opacity-50 z-40"
              onClick={() => setIsOpen(false)}
            />
            
            {/* Menu panel */}
            <motion.div
              initial={{ x: '-100%' }}
              animate={{ x: 0 }}
              exit={{ x: '-100%' }}
              className="fixed left-0 top-0 h-full w-80 bg-white shadow-lg z-50 p-6"
            >
              <div className="flex items-center justify-between mb-8">
                <h2 className="text-lg font-semibold">Menu</h2>
                <button
                  onClick={() => setIsOpen(false)}
                  className="p-2 rounded-md text-gray-600 hover:bg-gray-100"
                  aria-label="Close navigation menu"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
              
              <nav className="space-y-4">
                {/* Navigation items */}
              </nav>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </>
  );
};
```

## 12. Testing Strategy

### 12.1 Component Testing

```typescript
// __tests__/components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '../components/ui/Button';

describe('Button Component', () => {
  it('renders with correct text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });
  
  it('handles click events', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    
    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
  
  it('shows loading state', () => {
    render(<Button isLoading>Loading</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
  
  it('applies correct variant styles', () => {
    render(<Button variant="danger">Delete</Button>);
    expect(screen.getByRole('button')).toHaveClass('bg-red-600');
  });
});
```

### 12.2 Integration Testing

```typescript
// __tests__/integration/AuthFlow.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { App } from '../App';
import { server } from '../mocks/server';

describe('Authentication Flow', () => {
  beforeAll(() => server.listen());
  afterEach(() => server.resetHandlers());
  afterAll(() => server.close());
  
  it('allows user to login successfully', async () => {
    render(
      <BrowserRouter>
        <App />
      </BrowserRouter>
    );
    
    // Navigate to login page
    fireEvent.click(screen.getByRole('link', { name: /sign in/i }));
    
    // Fill login form
    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'test@example.com' }
    });
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password123' }
    });
    
    // Submit form
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));
    
    // Verify redirect to dashboard
    await waitFor(() => {
      expect(screen.getByText(/welcome back/i)).toBeInTheDocument();
    });
  });
});
```

### 12.3 E2E Testing with Playwright

```typescript
// e2e/login.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Login Flow', () => {
  test('successful login redirects to feed', async ({ page }) => {
    await page.goto('/auth/login');
    
    await page.fill('[data-testid="email-input"]', 'test@example.com');
    await page.fill('[data-testid="password-input"]', 'password123');
    await page.click('[data-testid="login-button"]');
    
    await expect(page).toHaveURL('/feed');
    await expect(page.locator('[data-testid="user-menu"]')).toBeVisible();
  });
  
  test('invalid credentials show error message', async ({ page }) => {
    await page.goto('/auth/login');
    
    await page.fill('[data-testid="email-input"]', 'invalid@example.com');
    await page.fill('[data-testid="password-input"]', 'wrongpassword');
    await page.click('[data-testid="login-button"]');
    
    await expect(page.locator('[data-testid="error-message"]')).toContainText(
      'Invalid credentials'
    );
  });
});
```

## 13. Build & Deployment

### 13.1 Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@/components': resolve(__dirname, 'src/components'),
      '@/hooks': resolve(__dirname, 'src/hooks'),
      '@/stores': resolve(__dirname, 'src/stores'),
      '@/services': resolve(__dirname, 'src/services'),
      '@/utils': resolve(__dirname, 'src/utils'),
      '@/types': resolve(__dirname, 'src/types')
    }
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          router: ['react-router-dom'],
          ui: ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
          utils: ['date-fns', 'clsx', 'tailwind-merge']
        }
      }
    },
    sourcemap: true,
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    }
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true
      }
    }
  }
});
```

### 13.2 Docker Configuration

```dockerfile
# Dockerfile
# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci

# Copy source code and build
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built files to nginx
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### 13.3 Environment Configuration

```typescript
// src/config/environment.ts
interface Environment {
  API_BASE_URL: string;
  WS_BASE_URL: string;
  APP_ENV: 'development' | 'staging' | 'production';
  SENTRY_DSN?: string;
  GA_TRACKING_ID?: string;
}

export const env: Environment = {
  API_BASE_URL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3001/api/v1',
  WS_BASE_URL: import.meta.env.VITE_WS_BASE_URL || 'ws://localhost:3001',
  APP_ENV: (import.meta.env.VITE_APP_ENV as Environment['APP_ENV']) || 'development',
  SENTRY_DSN: import.meta.env.VITE_SENTRY_DSN,
  GA_TRACKING_ID: import.meta.env.VITE_GA_TRACKING_ID
};
```

## 14. Performance Monitoring

### 14.1 Performance Metrics

```typescript
// utils/performance.ts
export class PerformanceMonitor {
  private static instance: PerformanceMonitor;
  
  static getInstance(): PerformanceMonitor {
    if (!PerformanceMonitor.instance) {
      PerformanceMonitor.instance = new PerformanceMonitor();
    }
    return PerformanceMonitor.instance;
  }
  
  measurePageLoad(pageName: string) {
    const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
    
    const metrics = {
      page: pageName,
      loadTime: navigation.loadEventEnd - navigation.loadEventStart,
      domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
      firstPaint: this.getFirstPaint(),
      firstContentfulPaint: this.getFirstContentfulPaint()
    };
    
    this.sendMetrics(metrics);
  }
  
  private getFirstPaint(): number {
    const paint = performance.getEntriesByType('paint').find(entry => entry.name === 'first-paint');
    return paint?.startTime || 0;
  }
  
  private getFirstContentfulPaint(): number {
    const paint = performance.getEntriesByType('paint').find(entry => entry.name === 'first-contentful-paint');
    return paint?.startTime || 0;
  }
  
  private sendMetrics(metrics: any) {
    // Send to analytics service
    if (env.GA_TRACKING_ID) {
      gtag('event', 'page_performance', metrics);
    }
  }
}
```

### 14.2 Error Boundary

```typescript
// components/ErrorBoundary.tsx
interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

export class ErrorBoundary extends React.Component<
  React.PropsWithChildren<{}>,
  ErrorBoundaryState
> {
  constructor(props: React.PropsWithChildren<{}>) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null
    };
  }
  
  static getDerivedStateFromError(error: Error): Partial<ErrorBoundaryState> {
    return { hasError: true };
  }
  
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    this.setState({
      error,
      errorInfo
    });
    
    // Log error to monitoring service
    if (env.SENTRY_DSN) {
      Sentry.captureException(error, {
        contexts: { errorInfo }
      });
    }
  }
  
  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
          <div className="max-w-md w-full bg-white shadow-lg rounded-lg p-6">
            <div className="flex items-center mb-4">
              <AlertTriangle className="h-8 w-8 text-red-500 mr-3" />
              <h1 className="text-xl font-semibold text-gray-900">
                Something went wrong
              </h1>
            </div>
            
            <p className="text-gray-600 mb-6">
              We're sorry, but something unexpected happened. Our team has been notified.
            </p>
            
            <div className="flex space-x-3">
              <Button
                onClick={() => window.location.reload()}
                variant="primary"
              >
                Reload Page
              </Button>
              
              <Button
                onClick={() => window.history.back()}
                variant="outline"
              >
                Go Back
              </Button>
            </div>
          </div>
        </div>
      );
    }
    
    return this.props.children;
  }
}
```

This comprehensive frontend design document provides a solid foundation for building the SportLink web application with modern React practices, ensuring scalability, maintainability, and excellent user experience. The architecture supports all features outlined in the PRD while being flexible enough to accommodate future enhancements.
