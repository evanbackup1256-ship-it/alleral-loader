"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { fetchLiveStatus, fetchSite } from "@/lib/api";

export const siteQueryKey = ["site"] as const;
export const liveStatusQueryKey = ["live-status"] as const;

function livePollInterval() {
  if (typeof document === "undefined") return 15_000;
  return document.hidden ? false : 15_000;
}

export function useSiteQuery() {
  return useQuery({
    queryKey: siteQueryKey,
    queryFn: fetchSite,
    staleTime: 30_000,
    refetchInterval: 60_000,
  });
}

export function useLiveStatusQuery() {
  return useQuery({
    queryKey: liveStatusQueryKey,
    queryFn: fetchLiveStatus,
    staleTime: 5_000,
    refetchInterval: livePollInterval,
    refetchIntervalInBackground: false,
  });
}

export function useLiveSyncMeta() {
  const query = useLiveStatusQuery();
  return {
    data: query.data,
    error: query.error,
    loading: query.isLoading,
    fetching: query.isFetching,
    dataUpdatedAt: query.dataUpdatedAt,
    refresh: query.refetch,
    online: query.isSuccess && query.data?.ok !== false,
  };
}

export function useInvalidateLive() {
  const client = useQueryClient();
  return () => client.invalidateQueries({ queryKey: liveStatusQueryKey });
}
