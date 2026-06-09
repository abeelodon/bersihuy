export type AdminProfile = {
  id: string;
  name: string;
  email: string;
  role: "admin";
};

export type AdminOrderRow = {
  id: string;
  orderNumber: string;
  customerId: string;
  customerName: string;
  status: string;
  effectiveStatus: string;
  scheduleDate: string | null;
  scheduleTime: string | null;
  address: string;
  customerNote: string | null;
  selectedScent: string | null;
  subtotalAmount: number;
  adminFee: number;
  discountAmount: number;
  totalAmount: number;
  serviceName: string;
  itemNames: string[];
  addonNames: string[];
  paymentStatus: string | null;
  taskId: string | null;
  taskStatus: string | null;
  beforePhotoUrl: string | null;
  afterPhotoUrl: string | null;
  assignedStaffId: string | null;
  assignedStaffName: string | null;
  createdAt: string | null;
};

export type AdminStaffProfile = {
  id: string;
  fullName: string;
  email: string;
  phone: string | null;
  avatarUrl: string | null;
  staffArea: string | null;
  staffShift: string | null;
  baseLocation: string | null;
  workSchedule: string | null;
  isActive: boolean;
  assignedTasks: number;
  completedTasks: number;
  inProgressTasks: number;
  averageRating: number;
  complaintCount: number;
  recentTasks: AdminOrderRow[];
};

export type AdminServiceItem = {
  id: string;
  name: string;
  slug: string | null;
  category: string;
  description: string;
  basePrice: number;
  durationMinutes: number;
  rating: number;
  imageAssetPath: string | null;
  isActive: boolean;
};

export type AdminProductItem = {
  id: string;
  name: string;
  slug: string | null;
  description: string;
  price: number;
  imageAssetPath: string | null;
  isAddon: boolean;
  isActive: boolean;
};

export type AdminComplaintRow = {
  id: string;
  orderId: string;
  orderNumber: string;
  customerId: string;
  customerName: string;
  serviceName: string;
  assignedStaffId: string | null;
  handledBy: string | null;
  handledByName: string | null;
  status: string;
  category: string;
  description: string;
  evidenceUrl: string | null;
  resolutionNote: string | null;
  createdAt: string | null;
  updatedAt: string | null;
};

export type AdminTopItem = {
  name: string;
  count: number;
  revenue: number;
  imageAssetPath: string | null;
};

export type AdminTrendPoint = {
  label: string;
  date: string;
  orders: number;
  revenue: number;
};

export type AdminDashboardSummary = {
  totalOrders: number;
  todayOrders: number;
  waitingAssignment: number;
  assigned: number;
  inProgress: number;
  completed: number;
  openComplaints: number;
  totalRevenue: number;
  monthlyRevenue: number;
  averageOrderValue: number;
  averageRating: number;
};

export type AdminDashboardData = {
  profile: AdminProfile;
  summary: AdminDashboardSummary;
  orders: AdminOrderRow[];
  staff: AdminStaffProfile[];
  services: AdminServiceItem[];
  products: AdminProductItem[];
  complaints: AdminComplaintRow[];
  topServices: AdminTopItem[];
  topProducts: AdminTopItem[];
  trends: AdminTrendPoint[];
};
