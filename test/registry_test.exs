defmodule KV.RegistryTest do
  use ExUnit.Case, async: true
  doctest KV

  @shopping "shopping"

  setup do
    registry = start_supervised!(KV.Registry)
    %{registry: registry}
  end

  test "spawn buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, @shopping) == :error

    KV.Registry.create(registry, @shopping)
    assert {:ok, bucket} = KV.Registry.lookup(registry, @shopping)

    milk_val = 3
    KV.Bucket.put(bucket, "milk", milk_val)
    assert KV.Bucket.get(bucket, "milk") == milk_val
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, @shopping)
    {:ok, bucket} = KV.Registry.lookup(registry, @shopping)
    Agent.stop(bucket)
    assert KV.Registry.lookup(registry, @shopping) == :error
  end
end
