defmodule KV.BucketTest do
  use ExUnit.Case, async: true
  doctest KV

  setup do
    bucket = start_supervised!(KV.Bucket)
    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    milk_val = 3
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", milk_val)
    assert KV.Bucket.get(bucket, "milk") == milk_val

    deleted = KV.Bucket.delete(bucket, "milk")
    assert deleted == milk_val
    assert KV.Bucket.get(bucket, "milk") == nil
  end

  test "are temporary workers" do
    assert Supervisor.child_spec(KV.Bucket, []).restart == :temporary
  end
end
