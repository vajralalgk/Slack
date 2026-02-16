"""
============================================================================
Enterprise Cloud Transformation Platform (ECTP)
Unit Tests for Core Utilities
Author: Gopi Krishna Vajrala
============================================================================
"""

from datetime import datetime, timezone

from src.core.utils.helpers import (
    generate_id,
    now_utc,
    sanitize_input,
    build_aws_arn,
    mask_sensitive_string,
)


class TestGenerateId:
    """Tests for the generate_id utility function."""

    def test_default_prefix(self):
        """Test that default prefix is 'ectp'."""
        result = generate_id()
        assert result.startswith("ectp-")

    def test_custom_prefix(self):
        """Test custom prefix."""
        result = generate_id("mig")
        assert result.startswith("mig-")

    def test_unique_ids(self):
        """Test that generated IDs are unique."""
        ids = {generate_id() for _ in range(100)}
        assert len(ids) == 100  # All should be unique

    def test_id_format(self):
        """Test ID format: prefix-12hexchars."""
        result = generate_id("test")
        parts = result.split("-")
        assert parts[0] == "test"
        assert len(parts[1]) == 12


class TestNowUtc:
    """Tests for the now_utc utility function."""

    def test_returns_utc(self):
        """Test that returned datetime is UTC."""
        result = now_utc()
        assert result.tzinfo == timezone.utc

    def test_returns_datetime(self):
        """Test that result is a datetime object."""
        result = now_utc()
        assert isinstance(result, datetime)


class TestSanitizeInput:
    """Tests for the sanitize_input utility function."""

    def test_strips_whitespace(self):
        """Test whitespace stripping."""
        assert sanitize_input("  hello  ") == "hello"

    def test_removes_null_bytes(self):
        """Test null byte removal."""
        assert sanitize_input("hello\x00world") == "helloworld"

    def test_removes_control_characters(self):
        """Test control character removal."""
        assert sanitize_input("hello\x01\x02world") == "helloworld"

    def test_preserves_newlines(self):
        """Test that newlines are preserved."""
        assert sanitize_input("hello\nworld") == "hello\nworld"

    def test_enforces_max_length(self):
        """Test maximum length enforcement."""
        result = sanitize_input("a" * 2000, max_length=100)
        assert len(result) == 100

    def test_non_string_input(self):
        """Test handling of non-string input."""
        assert sanitize_input(123) == "123"


class TestBuildAwsArn:
    """Tests for the build_aws_arn utility function."""

    def test_basic_arn(self):
        """Test basic ARN construction."""
        result = build_aws_arn("ec2", "instance", "i-123")
        assert result == "arn:aws:ec2:us-east-1::instance/i-123"

    def test_with_account_id(self):
        """Test ARN with account ID."""
        result = build_aws_arn("s3", "bucket", "my-bucket", account_id="123456789012")
        assert "123456789012" in result

    def test_custom_region(self):
        """Test ARN with custom region."""
        result = build_aws_arn("rds", "db", "mydb", region="us-west-2")
        assert "us-west-2" in result


class TestMaskSensitiveString:
    """Tests for the mask_sensitive_string utility function."""

    def test_basic_masking(self):
        """Test basic string masking."""
        result = mask_sensitive_string("sk-1234567890abcdef")
        assert result.endswith("cdef")
        assert result.startswith("*")

    def test_short_string(self):
        """Test masking of short string."""
        result = mask_sensitive_string("abc")
        assert result == "***"

    def test_empty_string(self):
        """Test masking of empty string."""
        result = mask_sensitive_string("")
        assert result == ""

    def test_custom_visible_chars(self):
        """Test custom visible character count."""
        result = mask_sensitive_string("1234567890", visible_chars=6)
        assert result == "****567890"
